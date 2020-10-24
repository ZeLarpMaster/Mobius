defmodule Mobius.Stubs.Socket do
  @moduledoc false

  use GenServer

  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Socket

  require Logger

  @behaviour Socket

  @type msg :: :close | {:msg, any}

  @type state :: %{
          url: String.t(),
          query: String.t(),
          shard: ShardInfo.t(),
          test_pid: pid | nil
        }

  # Socket callbacks
  @impl Socket
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl Socket
  @spec send_message(term, GenServer.server()) :: :ok
  def send_message(message, socket) do
    GenServer.cast(socket, {:send, message})
  end

  @impl Socket
  @spec close(GenServer.server()) :: :ok
  def close(socket) do
    GenServer.call(socket, :close)
  end

  # Stub API
  @spec set_owner(ShardInfo.t()) :: :ok
  def set_owner(shard) do
    GenServer.call(Socket.via(shard), {:set_test, self()})
  end

  # GenServer and :gun stuff
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    state = %{
      url: Keyword.fetch!(opts, :url),
      query: Keyword.fetch!(opts, :query),
      shard: Keyword.fetch!(opts, :shard),
      test_pid: nil
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:send, payload}, state) do
    unless state.test_pid == nil do
      send(state.test_pid, {:socket_msg, payload})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:close, _from, state) do
    unless state.test_pid == nil do
      send(state.test_pid, :socket_close)
    end

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
