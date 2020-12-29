defmodule Mobius.Services.ShardRatelimiter do
  @moduledoc false

  alias Mobius.Core.ShardInfo

  @type bucket :: {String.t(), pos_integer(), pos_integer()}

  @callback start_link(keyword) :: GenServer.on_start()
  @callback request_access(bucket()) :: :ok | :ratelimited

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts), do: impl().start_link(opts)

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(opts), do: impl().child_spec(opts)

  @doc """
  Requests access to shard commands and the service either grants the access with an `:ok` or
  rejects it with a `:ratelimited`

  Shards' ratelimits are namespaced and don't interact with each other.
  The suffix is used to split ratelimits between different purposes.

  The default value is shards' global ratelimit.
  Its max amount is 120, but 5 are reserved by design to keeping the bot alive.
  Specifically heartbeats, identifies, and resumes which may occur during normal execution.
  See https://discord.com/developers/docs/topics/gateway#rate-limiting for more details.
  """
  @spec request_access(ShardInfo.t(), String.t(), integer, integer) :: :ok | :ratelimited
  def request_access(shard, suffix \\ "global", window_ms \\ 60_000, max_amount \\ 115) do
    bucket = "shard:#{shard.number}:#{suffix}"
    impl().request_access({bucket, window_ms, max_amount})
  end

  defp impl do
    Application.get_env(:mobius, :ratelimiter_impl, __MODULE__.SelfRefill)
  end
end
