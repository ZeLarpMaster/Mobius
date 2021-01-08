defmodule Mobius.Stubs.CommandsRatelimiter do
  @moduledoc false

  use GenServer

  alias Mobius.Services.CommandsRatelimiter

  @behaviour CommandsRatelimiter

  @type state :: %{
          test_pid: pid | nil,
          ratelimit_reply: :ok | :ratelimited
        }

  # CommandsRatelimiter callbacks
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl CommandsRatelimiter
  @spec request_access(CommandsRatelimiter.bucket()) :: :ok | :ratelimited
  def request_access(bucket) do
    GenServer.call(__MODULE__, {:request, bucket})
  end

  # Stub API
  @spec set_ratelimited(boolean) :: :ok
  def set_ratelimited(value) do
    GenServer.call(__MODULE__, {:set_ratelimited, value})
  end

  @spec set_owner() :: :ok
  def set_owner do
    GenServer.call(__MODULE__, {:set_test, self()})
  end

  # GenServer stuff
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(_opts) do
    state = %{
      test_pid: nil,
      ratelimit_reply: :ok
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:request, bucket}, _from, state) do
    if state.test_pid != nil do
      send(state.test_pid, {:ratelimit_requested, bucket})
    end

    {:reply, state.ratelimit_reply, state}
  end

  # Stub-only callbacks
  def handle_call({:set_ratelimited, ratelimited?}, _from, state) do
    reply = if ratelimited?, do: :ratelimited, else: :ok
    {:reply, :ok, put_in(state.ratelimit_reply, reply)}
  end

  def handle_call({:set_test, pid}, _from, %{test_pid: nil} = state) do
    Process.monitor(pid)
    {:reply, :ok, put_in(state.test_pid, pid)}
  end

  def handle_call({:set_test, _pid}, _from, state) do
    {:reply, {:error, :already_assigned}, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{test_pid: t_pid} = state)
      when pid == t_pid do
    {:noreply, put_in(state.test_pid, nil)}
  end
end
