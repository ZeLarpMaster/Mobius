defmodule Mobius.Shard.Socket.Proxy do
  @moduledoc false

  alias Mobius.Shard.Socket

  @behaviour Socket

  @impl Socket
  def start_link(_opts) do
    {:ok, self()}
  end

  @impl Socket
  def send_message(socket, message) do
    send(socket, {:socket_send, message})
    :ok
  end

  @impl Socket
  def close(socket) do
    send(socket, :socket_close)
    :ok
  end
end
