defmodule Mobius.Services.ConnectionRatelimiter do
  @moduledoc false

  @block_message :connect

  @doc """
  Unblocks processes waiting in `wait_until_can_connect/0`

  This function is *NOT* for usage in modules other than those implementing this service
  """
  @spec unblock_client(pid) :: :ok
  def unblock_client(pid) do
    send(pid, @block_message)
    :ok
  end

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(impl(), opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Block the calling process until it has the authorization to connect

  Only one process may connect in any 5 seconds timeframe.
  Therefore, to ensure the network jitter doesn't cause problems,
  we will wait until Discord sends us a reply before starting the 5 second timer.
  This reply is notified through `ack_connected/1`.

  The calling process is also monitored to automatically ack if the process crashes.
  If the process never acks, but also never crashes,
  it will automatically ack after a timeout of 10 seconds

  See https://discord.com/developers/docs/topics/gateway#rate-limiting for the few details
  """
  @spec wait_until_can_connect() :: :ok
  def wait_until_can_connect do
    GenServer.call(__MODULE__, {:connect, self()})
    block_client()
  end

  @doc """
  Ack that the process has succesfully connected to allow the next process to connect
  """
  @spec ack_connected() :: :ok
  def ack_connected do
    GenServer.cast(__MODULE__, {:connect_ack, self()})
    :ok
  end

  defp block_client do
    receive do
      @block_message -> :ok
    end
  end

  defp impl do
    Application.get_env(:mobius, :connection_ratelimiter_impl, __MODULE__.Timed)
  end
end
