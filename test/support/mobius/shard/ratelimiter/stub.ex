defmodule Mobius.Shard.Ratelimiter.Stub do
  @moduledoc false

  use GenServer

  alias Mobius.Shard.Ratelimiter

  @typep state :: %{
           parent: Process.dest(),
           is_empty?: boolean
         }

  @behaviour Ratelimiter

  @impl Ratelimiter
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    state = %{
      parent: Keyword.fetch!(opts, :parent),
      is_empty?: false
    }

    {:ok, state}
  end

  @impl Ratelimiter
  @spec request_access(pid, Ratelimiter.bucket()) :: :ok
  def request_access(server, {_, _, _} = bucket) do
    GenServer.call(server, {:request, bucket})
  end

  @spec set_emptiness(GenServer.server(), boolean) :: :ok
  def set_emptiness(server, empty?) do
    GenServer.call(server, {:set_empty, empty?})
  end

  @impl GenServer
  def handle_call({:set_empty, empty?}, _from, state) do
    {:reply, :ok, %{state | is_empty?: empty?}}
  end

  def handle_call({:request, {name, delay, tokens}}, _from, state) do
    send(state.parent, {:requested_access, name, delay, tokens})

    if state.is_empty? do
      {:reply, :ratelimited, state}
    else
      {:reply, :ok, state}
    end
  end
end
