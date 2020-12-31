defmodule Mobius.Services.ConnectionRatelimiter.Timed do
  @moduledoc false

  use GenServer

  alias Mobius.Services.ConnectionRatelimiter

  require Logger

  @type state :: %{
          queue: :queue.queue(pid),
          current: pid | nil,
          time_between_connections_ms: non_neg_integer,
          timer_ref: reference | nil,
          monitor_ref: reference | nil
        }

  # Server callbacks
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    state = %{
      queue: :queue.new(),
      current: nil,
      time_between_connections_ms: Keyword.fetch!(opts, :time_between_connections_ms),
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
  def handle_cast({:connect_ack, pid}, state) do
    cond do
      pid != state.current ->
        Logger.warn("Ack from #{inspect(pid)} when someone else was connecting")
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
    ref = Process.send_after(self(), :unblock_next, state.time_per_connection_ms)
    %{state | timer_ref: ref}
  end

  defp unblock_process(pid) do
    ref = Process.monitor(pid)
    ConnectionRatelimiter.unblock_client(pid)
    ref
  end
end
