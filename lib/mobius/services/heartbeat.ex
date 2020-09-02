defmodule Mobius.Services.Heartbeat do
  @moduledoc false

  use GenServer

  alias Mobius.Core.HeartbeatInfo
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Shard

  @typep state :: %{
           seq: integer,
           shard: ShardInfo.t(),
           interval_ms: integer,
           info: HeartbeatInfo.t()
         }

  @spec get_ping(ShardInfo.t()) :: integer
  def get_ping(shard) do
    GenServer.call(via(shard), :get_ping)
  end

  @spec request_heartbeat(ShardInfo.t()) :: :ok
  def request_heartbeat(shard) do
    GenServer.call(via(shard), :request)
  end

  @spec received_ack(ShardInfo.t()) :: :ok
  def received_ack(shard) do
    GenServer.call(via(shard), :ack)
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    shard = Keyword.fetch!(opts, :shard)

    state = %{
      seq: Shard.get_sequence_number(shard),
      shard: shard,
      interval_ms: Keyword.fetch!(opts, :interval_ms),
      info: HeartbeatInfo.new()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:request, _from, state) do
    # TODO: Send request and update info
    {:reply, :ok, state}
  end

  def handle_call(:ack, _from, state) do
    # TODO: Update info
    {:reply, :ok, state}
  end

  def handle_call(:get_ping, _from, state) do
    {:reply, state.info.ping, state}
  end

  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Heartbeat, shard}}
end
