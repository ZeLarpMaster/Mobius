defmodule Mobius.Services.Heartbeat do
  @moduledoc false

  use GenServer

  alias Mobius.Core.HeartbeatInfo
  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Shard
  alias Mobius.Services.Socket

  require Logger

  @typep state :: %{
           shard: ShardInfo.t(),
           interval_ms: integer,
           info: HeartbeatInfo.t()
         }

  @spec start_heartbeat(ShardInfo.t(), integer) :: DynamicSupervisor.on_start_child()
  def start_heartbeat(shard, interval_ms) do
    DynamicSupervisor.start_child(
      Mobius.Supervisor.Heartbeat,
      {__MODULE__, {shard, interval_ms: interval_ms}}
    )
  end

  @spec child_spec({ShardInfo.t(), keyword}) :: Supervisor.child_spec()
  def child_spec({shard, opts}) do
    %{
      id: shard,
      start: {__MODULE__, :start_link, [shard, opts]},
      restart: :transient
    }
  end

  @spec start_link(ShardInfo.t(), keyword) :: GenServer.on_start()
  def start_link(shard, opts) do
    GenServer.start_link(__MODULE__, opts ++ [shard: shard], name: via(shard))
  end

  @spec get_ping(ShardInfo.t()) :: integer
  def get_ping(shard) do
    GenServer.call(via(shard), :get_ping)
  end

  @spec request_heartbeat(ShardInfo.t(), integer) :: :ok
  def request_heartbeat(shard, seq) do
    GenServer.call(via(shard), {:request, seq})
  end

  @spec request_shutdown(ShardInfo.t()) :: :ok
  def request_shutdown(shard) do
    GenServer.call(via(shard), :shutdown)
  end

  @spec received_ack(ShardInfo.t()) :: {:ok, ping_ms :: integer}
  def received_ack(shard) do
    GenServer.call(via(shard), :ack)
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state(), {:continue, any}}
  def init(opts) do
    shard = Keyword.fetch!(opts, :shard)

    state = %{
      shard: shard,
      interval_ms: Keyword.fetch!(opts, :interval_ms),
      info: HeartbeatInfo.new()
    }

    {:ok, state, {:continue, :init_periodic_heartbeat}}
  end

  @impl GenServer
  @spec handle_continue(:init_periodic_heartbeat, state()) :: {:noreply, state()}
  def handle_continue(:init_periodic_heartbeat, state) do
    maybe_send_heartbeat(true, state)
  end

  @impl GenServer
  def handle_call({:request, seq}, _from, state) do
    send_heartbeat(state.shard, seq)
    state = update_in(state.info, &HeartbeatInfo.sending/1)
    {:reply, :ok, state}
  end

  def handle_call(:shutdown, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call(:ack, _from, state) do
    state = update_in(state.info, &HeartbeatInfo.received_ack/1)
    {:reply, :ok, state}
  end

  def handle_call(:get_ping, _from, state) do
    {:reply, state.info.ping, state}
  end

  @impl GenServer
  def handle_info(:heartbeat, state) do
    state.info
    |> HeartbeatInfo.can_send?()
    |> maybe_send_heartbeat(state)
  end

  defp maybe_send_heartbeat(true, state) do
    send_heartbeat(state.shard, Shard.get_sequence_number(state.shard))
    schedule_heartbeat(state.interval_ms)
    state = update_in(state.info, &HeartbeatInfo.sending/1)
    {:noreply, state}
  end

  defp maybe_send_heartbeat(false, state) do
    Logger.warn("Didn't receive a heartbeat ack in time")
    Socket.close(state.shard)
    {:stop, {:shutdown, :heartbeat_timeout}, state}
  end

  defp schedule_heartbeat(interval_ms), do: Process.send_after(self(), :heartbeat, interval_ms)
  defp send_heartbeat(shard, seq), do: seq |> Opcode.heartbeat() |> Socket.send_message(shard)
  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Heartbeat, shard}}
end
