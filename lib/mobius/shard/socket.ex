defmodule Mobius.Shard.Socket do
  @moduledoc false

  @callback start_link(opts :: keyword()) :: {:ok, pid}

  @callback send_message(socket :: pid, message :: term) :: :ok

  @callback close(socket :: pid) :: :ok

  @spec notify_message(pid, term) :: :ok
  def notify_message(parent, message) do
    send(parent, {:socket_message, message})
    :ok
  end

  @spec notify_closed(pid, integer, String.t()) :: :ok
  def notify_closed(parent, close_num, reason) do
    send(parent, {:socket_closed, close_num, reason})
    :ok
  end

  @spec notify_down(pid, String.t()) :: :ok
  def notify_down(parent, reason) do
    send(parent, {:socket_down, reason})
    :ok
  end

  @spec notify_up(pid) :: :ok
  def notify_up(parent) do
    send(parent, :socket_up)
    :ok
  end

  # Abstracting the implementation config
  @spec start_link([any]) :: {:ok, pid}
  def start_link(args), do: impl().start_link(args)

  @spec send_message(pid, term) :: :ok
  def send_message(socket, message), do: impl().send_message(socket, message)

  @spec close(pid) :: :ok
  def close(socket), do: impl().close(socket)

  defp impl do
    Application.fetch_env!(:mobius, :socket_impl)
  end
end
