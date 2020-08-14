defmodule Mobius.Api.Middleware.Ratelimit.Server do
  @moduledoc false

  use GenServer

  @type state :: %{bucket_map: %{}, global_limit: nil | integer, table: :ets.tid()}

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @spec update_ratelimit(GenServer.server(), any, String.t(), integer, integer) :: :ok
  def update_ratelimit(server, route, bucket, remaining, reset_after) do
    reset = System.monotonic_time(:millisecond) + reset_after
    :ok = GenServer.call(server, {:update, route, bucket, remaining, reset})
  end

  @spec wait_ratelimit(GenServer.server(), any) :: :ok
  def wait_ratelimit(server, route) do
    case GenServer.call(server, {:request, route}) do
      :ok -> :ok
      {:wait, time} -> Process.sleep(time)
    end
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(_opts) do
    state = %{
      table: :ets.new(__MODULE__, [:set, :protected]),
      bucket_map: %{},
      global_limit: nil
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:reset_global, state) do
    {:noreply, %{state | global_limit: nil}}
  end

  @impl GenServer
  def handle_call({:update, "global", _, _, reset}, _from, state) do
    Process.send_after(self(), :reset_global, time_until(reset))
    {:reply, :ok, %{state | global_limit: reset}}
  end

  def handle_call({:update, route, bucket, remaining, reset}, _from, state) do
    :ets.insert(state.table, {bucket, remaining, reset})

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

    case :ets.lookup(state.table, find_bucket(state, route)) do
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
