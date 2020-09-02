defmodule Mobius.Services.Socket do
  @moduledoc false

  alias Mobius.Services.Shard

  @callback start_link(opts :: keyword) :: GenServer.on_start()
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(args), do: impl().start_link(args)

  @callback send_message(socket :: GenServer.server(), message :: term) :: :ok
  @spec send_message(GenServer.server(), term) :: :ok
  def send_message(socket, message), do: impl().send_message(socket, message)

  @callback close(socket :: GenServer.server()) :: :ok
  @spec close(GenServer.server()) :: :ok
  def close(socket), do: impl().close(socket)

  @spec receive_payload(Mobius.Core.ShardInfo.t(), any) :: :ok
  defdelegate receive_payload(shard, payload), to: Shard

  @spec notify_closed(GenServer.server(), integer, String.t()) :: :ok
  def notify_closed(parent, close_num, reason) do
    # TODO: Notify the gateway and let it figure out what to do
    :ok
  end

  @spec notify_down(pid, String.t()) :: :ok
  def notify_down(parent, reason) do
    # TODO: Tell heartbeat service to stop
    :ok
  end

  @spec notify_up(pid) :: :ok
  def notify_up(parent) do
    # TODO: Tell heartbeat service to reset
    :ok
  end

  defp via(shard), do: {:via, Registry, {Mobius.Registry.Socket, shard}}
  defp impl, do: Application.get_env(:mobius, :socket_impl, __MODULE__)
end
