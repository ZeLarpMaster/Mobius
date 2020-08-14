defmodule Mobius.Shard.Gatekeeper.Timed do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Shard.Gatekeeper

  @behaviour Gatekeeper

  @time_per_connection_ms Application.get_env(:mobius, :time_between_connections_ms, 5000)

  @type state :: %{
          queue: :queue.queue(pid),
          current: pid | nil,
          timer_ref: reference | nil,
          monitor_ref: reference | nil
        }

  # Client API
  @impl Gatekeeper
  @spec start_link([atom | nil]) :: {:ok, pid}
  def start_link([name]) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @impl Gatekeeper
  @spec wait_until_can_identify(atom | pid) :: :ok
  def wait_until_can_identify(server) do
    GenServer.call(server, {:connect, self()})
    Gatekeeper.block_client()
  end

  @impl Gatekeeper
  @spec ack_identified(atom | pid) :: :ok
  def ack_identified(server) do
    GenServer.cast(server, {:identify_ack, self()})
    :ok
  end

  # Server callbacks
  @impl GenServer
  @spec init(nil) :: {:ok, state()}
  def init(nil) do
    state = %{
      queue: :queue.new(),
      current: nil,
      timer_ref: nil,
      monitor_ref: nil
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:connect, pid}, _from, %{current: nil} = state) do
    ref = unblock_process(pid)
    {:reply, :ok, %{state | current: pid, monitor_ref: ref}}
  end

  def handle_call({:connect, pid}, _from, state) do
    {:reply, :ok, %{state | queue: :queue.in(pid, state.queue)}}
  end

  @impl GenServer
  def handle_cast({:identify_ack, pid}, state) do
    cond do
      pid != state.current ->
        Logger.warn("Ack from #{inspect(pid)} when someone else was identifying")
        {:noreply, state}

      state.timer_ref != nil ->
        Logger.warn("#{inspect(state.current)} tried to ack again")
        {:noreply, state}

      true ->
        Process.demonitor(state.monitor_ref, [:flush])
        {:noreply, unblock_later(%{state | monitor_ref: nil})}
    end
  end

  @impl GenServer
  def handle_info(:unblock_next, state) do
    state =
      case :queue.out(state.queue) do
        {{:value, pid}, queue} ->
          ref = unblock_process(pid)
          %{state | current: pid, queue: queue, monitor_ref: ref}

        {:empty, _q} ->
          %{state | current: nil}
      end

    {:noreply, %{state | timer_ref: nil}}
  end

  def handle_info({:DOWN, _, _, pid, _}, %{current: conn_pid} = state) when pid == conn_pid do
    {:noreply, unblock_later(%{state | monitor_ref: nil})}
  end

  defp unblock_later(state) do
    ref = Process.send_after(self(), :unblock_next, @time_per_connection_ms)
    %{state | timer_ref: ref}
  end

  defp unblock_process(pid) do
    ref = Process.monitor(pid)
    Gatekeeper.unblock_client(pid)
    ref
  end
end
