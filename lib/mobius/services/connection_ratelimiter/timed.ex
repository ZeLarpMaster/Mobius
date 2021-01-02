defmodule Mobius.Services.ConnectionRatelimiter.Timed do
  @moduledoc false

  use GenServer

  alias Mobius.Services.ConnectionRatelimiter

  require Logger

  @behaviour ConnectionRatelimiter

  @type state :: %{
          queue: :queue.queue(pid),
          current: pid | nil,
          connection_delay_ms: non_neg_integer,
          ack_timeout_ms: non_neg_integer,
          timeout_ref: reference | nil,
          delay_ref: reference | nil,
          monitor_ref: reference | nil
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

  # Server callbacks
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    state = %{
      queue: :queue.new(),
      current: nil,
      connection_delay_ms: Keyword.fetch!(opts, :connection_delay_ms),
      ack_timeout_ms: Keyword.fetch!(opts, :ack_timeout_ms),
      timeout_ref: nil,
      delay_ref: nil,
      monitor_ref: nil
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:connect, pid, callback}, _from, %{current: nil} = state) do
    {:reply, :ok, unblock_process(state, pid, callback)}
  end

  def handle_call({:connect, pid, callback}, _from, state) do
    {:reply, :ok, %{state | queue: :queue.in({pid, callback}, state.queue)}}
  end

  @impl GenServer
  def handle_cast({:connect_ack, pid}, state) do
    cond do
      pid != state.current ->
        Logger.warn("Ack from #{inspect(pid)} when someone else was connecting")
        {:noreply, state}

      state.delay_ref != nil ->
        Logger.warn("#{inspect(state.current)} tried to ack again")
        {:noreply, state}

      true ->
        Process.cancel_timer(state.timeout_ref)
        Process.demonitor(state.monitor_ref, [:flush])
        {:noreply, unblock_later(%{state | monitor_ref: nil, timeout_ref: nil})}
    end
  end

  @impl GenServer
  def handle_info(:ack_timeout, state) do
    GenServer.cast(__MODULE__, {:connect_ack, state.current})
    {:noreply, state}
  end

  def handle_info(:unblock_next, state) do
    state =
      case :queue.out(state.queue) do
        {{:value, {pid, func}}, queue} -> unblock_process(%{state | queue: queue}, pid, func)
        {:empty, _q} -> %{state | current: nil}
      end

    {:noreply, %{state | delay_ref: nil}}
  end

  def handle_info({:DOWN, _, _, pid, _}, %{current: conn_pid} = state) when pid == conn_pid do
    {:noreply, unblock_later(%{state | monitor_ref: nil})}
  end

  defp unblock_process(state, pid, callback) do
    callback.()
    monitor_ref = Process.monitor(pid)
    timeout_ref = Process.send_after(self(), :ack_timeout, state.ack_timeout_ms)
    %{state | current: pid, monitor_ref: monitor_ref, timeout_ref: timeout_ref}
  end

  defp unblock_later(state) do
    delay_ref = Process.send_after(self(), :unblock_next, state.connection_delay_ms)
    %{state | delay_ref: delay_ref}
  end
end
