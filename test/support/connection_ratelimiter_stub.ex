defmodule Mobius.Stubs.ConnectionRatelimiter do
  @moduledoc false

  use GenServer

  alias Mobius.Services.ConnectionRatelimiter

  @behaviour ConnectionRatelimiter

  @type state :: %{
          test_pid: pid | nil
        }

  # Client API
  @impl ConnectionRatelimiter
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl ConnectionRatelimiter
  @spec wait_until_can_connect(ConnectionRatelimiter.connect_callback()) :: :ok
  def wait_until_can_connect(callback) do
    GenServer.call(__MODULE__, {:connect, self(), callback})
  end

  @impl ConnectionRatelimiter
  @spec ack_connected() :: :ok
  def ack_connected do
    GenServer.cast(__MODULE__, {:connect_ack, self()})
    :ok
  end

  # Stub API
  @spec set_owner() :: :ok
  def set_owner do
    GenServer.call(__MODULE__, {:set_test, self()})
  end

  # GenServer stuff
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(_opts) do
    state = %{
      test_pid: nil
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:connect_ack, pid}, state) do
    if state.test_pid != nil do
      send(state.test_pid, {:connection_ack, pid})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:connect, pid, callback}, _from, state) do
    if state.test_pid != nil do
      send(state.test_pid, {:connection_request, pid})
    end

    callback.()
    {:reply, :ok, state}
  end

  # Stub-only callbacks
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
