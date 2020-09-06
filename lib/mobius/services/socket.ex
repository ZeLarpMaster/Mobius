defmodule Mobius.Services.Socket do
  @moduledoc false

  require Logger

  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Shard
  alias Mobius.Services.Heartbeat

  @spec start_socket(ShardInfo.t(), String.t(), map) :: DynamicSupervisor.on_start_child()
  def start_socket(shard, url, query) do
    DynamicSupervisor.start_child(
      Mobius.Supervisor.Socket,
      {__MODULE__, {shard, url: url, query: query}}
    )
  end

  @spec child_spec({ShardInfo.t(), keyword}) :: Supervisor.child_spec()
  def child_spec({shard, opts}) do
    %{
      id: shard,
      start: {__MODULE__, :start_link, [shard, opts]},
      restart: :permanent
    }
  end

  @callback start_link(opts :: keyword) :: GenServer.on_start()
  @spec start_link(ShardInfo.t(), keyword) :: GenServer.on_start()
  def start_link(shard, opts), do: impl().start_link(opts ++ [shard: shard, name: via(shard)])

  @callback send_message(server :: GenServer.server(), message :: term) :: :ok
  @spec send_message(ShardInfo.t(), term) :: :ok
  def send_message(shard, message), do: impl().send_message(via(shard), message)

  @callback close(socket :: GenServer.server()) :: :ok
  @spec close(ShardInfo.t()) :: :ok
  def close(shard), do: impl().close(via(shard))

  @spec notify_payload(ShardInfo.t(), any) :: :ok
  defdelegate notify_payload(shard, payload), to: Shard

  @spec notify_closed(ShardInfo.t(), integer, String.t()) :: :ok
  defdelegate notify_closed(shard, close_num, reason), to: Shard

  @spec notify_down(ShardInfo.t(), String.t()) :: :ok
  def notify_down(shard, reason) do
    Logger.warn("Socket is down with the reason #{inspect(reason)}")
    Heartbeat.request_shutdown(shard)
  end

  @spec notify_up(ShardInfo.t()) :: :ok
  def notify_up(_shard) do
    Logger.warn("Socket reconnected")
  end

  defp via(shard), do: {:via, Registry, {Mobius.Registry.Socket, shard}}
  defp impl, do: Application.get_env(:mobius, :socket_impl, __MODULE__.Gun)
end
