defmodule Mobius.Services.RestRatelimiter do
  @moduledoc false

  use GenServer

  alias Mobius.Services.ETSShelf

  @type state :: %{bucket_map: %{}, global_limit: nil | integer}

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Updates a route's remaining ratelimit and tracks the route's bucket"
  @spec update_route_ratelimit(any, String.t(), integer, integer) :: :ok
  def update_route_ratelimit(route, bucket, remaining, reset_after) do
    reset = System.monotonic_time(:millisecond) + reset_after
    GenServer.call(__MODULE__, {:update, route, bucket, remaining, reset})
  end

  @doc "Updates the global ratelimit when it's exceeded with how long to wait for the reset"
  @spec update_global_ratelimit(integer) :: :ok
  def update_global_ratelimit(reset_after) do
    reset = System.monotonic_time(:millisecond) + reset_after
    GenServer.call(__MODULE__, {:update_global, reset})
  end

  @doc "Checks if the route's bucket is known and waits for it to be available if ratelimited"
  @spec wait_ratelimit(any) :: :ok
  def wait_ratelimit(route) do
    case GenServer.call(__MODULE__, {:request, route}) do
      :ok -> :ok
      {:wait, time} -> Process.sleep(time)
    end
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(_opts) do
    state = %{
      bucket_map: %{},
      global_limit: nil
    }

    :ok = ETSShelf.create_table(__MODULE__, [:set, :protected])
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:reset_global, state) do
    {:noreply, %{state | global_limit: nil}}
  end

  @impl GenServer
  def handle_call({:update_global, reset}, _from, state) do
    Process.send_after(self(), :reset_global, time_until(reset))

    {:reply, :ok, %{state | global_limit: reset}}
  end

  def handle_call({:update, route, bucket, remaining, reset}, _from, state) do
    :ets.insert(__MODULE__, {bucket, remaining, reset})

    {:reply, :ok, register_route(state, route, bucket)}
  end

  def handle_call({:request, "global"}, _from, state) do
    case state.global_limit do
      nil -> {:reply, :ok, state}
      time -> {:reply, {:wait, time_until(time)}, state}
    end
  end

  def handle_call({:request, route}, _from, state) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(__MODULE__, find_bucket(state, route)) do
      [] -> {:reply, :ok, state}
      [{_, _, expiration}] when now > expiration -> {:reply, :ok, state}
      [{_, remaining, _}] when remaining > 0 -> {:reply, :ok, state}
      [{_, _, expiration}] -> {:reply, {:wait, time_until(expiration)}, state}
    end
  end

  defp time_until(time), do: max(0, time - System.monotonic_time(:millisecond))

  defp find_bucket(%{bucket_map: map}, route), do: Map.get(map, route, route)

  defp register_route(state, route, bucket),
    do: %{state | bucket_map: Map.put(state.bucket_map, route, bucket)}
end
