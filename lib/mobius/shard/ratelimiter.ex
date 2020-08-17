defmodule Mobius.Shard.Ratelimiter do
  @moduledoc false

  @type bucket :: {String.t(), pos_integer(), pos_integer()}

  @callback start_link(keyword) :: {:ok, pid}
  @callback request_access(GenServer.server(), bucket()) :: :ok | :ratelimited

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts), do: impl().start_link(opts)

  @spec request_access(GenServer.server(), bucket()) :: :ok | :ratelimited
  def request_access(server, bucket), do: impl().request_access(server, bucket)

  defp impl, do: Application.get_env(:mobius, :ratelimiter_impl, __MODULE__.SelfRefill)
end
