defmodule Mobius.Services.ConnectionRatelimiter do
  @moduledoc false

  @type connect_callback :: (() -> any)

  @callback start_link(keyword) :: GenServer.on_start()
  @callback child_spec(keyword) :: Supervisor.child_spec()
  @callback wait_until_can_connect(connect_callback()) :: :ok
  @callback ack_connected() :: :ok

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts), do: impl().start_link(opts)

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(opts), do: impl().child_spec(opts)

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
  @spec wait_until_can_connect(connect_callback()) :: :ok
  def wait_until_can_connect(callback), do: impl().wait_until_can_connect(callback)

  @doc """
  Ack that the process has succesfully connected to allow the next process to connect
  """
  @spec ack_connected() :: :ok
  def ack_connected, do: impl().ack_connected()

  defp impl do
    Application.get_env(:mobius, :connection_ratelimiter_impl, __MODULE__.Timed)
  end
end
