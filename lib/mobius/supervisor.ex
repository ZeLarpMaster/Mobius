defmodule Mobius.Supervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl Supervisor
  def init(opts) do
    bot = Keyword.fetch!(opts, :bot)

    shards =
      for i <- bot.shard_range do
        gateway(opts, i, Enum.count(bot.shard_range))
      end

    children =
      [
        {Registry, keys: :unique, name: bot.registry},
        {Mobius.Shard.Ratelimiter.SelfRefill, name: ratelimiter_name(bot)},
        {Mobius.Shard.Gatekeeper.Timed, [gatekeeper_name(bot)]}
      ] ++ shards

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 1)
  end

  @spec gateway(keyword, non_neg_integer(), pos_integer()) :: Supervisor.child_spec()
  def gateway(opts, shard_num, shard_count) do
    bot = Keyword.fetch!(opts, :bot)

    Supervisor.child_spec(
      {Mobius.Shard.Gateway,
       gateway_url: Keyword.fetch!(opts, :url),
       shard_num: shard_num,
       shard_count: shard_count,
       pubsub: pubsub_name(),
       bot_id: bot.id,
       token: Keyword.fetch!(opts, :token),
       intents: Keyword.fetch!(opts, :intents),
       ratelimiter: ratelimiter_name(bot),
       gatekeeper: gatekeeper_name(bot),
       name: gateway_name(bot, shard_num)},
      id: shard_num
    )
  end

  @spec gateway_name(Bot.t(), non_neg_integer()) :: GenServer.name()
  def gateway_name(bot, shard), do: {:via, Registry, {bot.registry, "gateway #{shard}"}}

  @spec pubsub_name() :: atom
  def pubsub_name, do: Mobius.PubSub

  defp ratelimiter_name(bot), do: {:via, Registry, {bot.registry, "ratelimiter"}}
  defp gatekeeper_name(bot), do: {:via, Registry, {bot.registry, "gatekeeper"}}
end
