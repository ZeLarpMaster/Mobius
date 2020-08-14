defmodule Mobius.Shard.Gatekeeper do
  @moduledoc false

  @type gatekeeper :: atom | pid

  @callback start_link([atom | nil]) :: {:ok, pid}

  @callback wait_until_can_identify(gatekeeper()) :: :ok

  @callback ack_identified(gatekeeper()) :: :ok

  @block_message :identify

  @spec block_client() :: :ok
  def block_client do
    receive do
      @block_message -> :ok
    end
  end

  @spec unblock_client(pid) :: :ok
  def unblock_client(pid) do
    send(pid, @block_message)
    :ok
  end

  # Abstracting the implementation config
  @spec start_link([atom | nil]) :: {:ok, pid}
  def start_link([_name] = arg), do: impl().start_link(arg)

  @spec wait_until_can_identify(gatekeeper()) :: :ok
  def wait_until_can_identify(gatekeeper), do: impl().wait_until_can_identify(gatekeeper)

  @spec ack_identified(gatekeeper()) :: :ok
  def ack_identified(gatekeeper), do: impl().ack_identified(gatekeeper)

  defp impl do
    Application.fetch_env!(:mobius, :gatekeeper_impl)
  end
end
