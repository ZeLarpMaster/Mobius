defmodule Mobius.Services.Bot do
  @moduledoc false

  use GenServer

  alias Mobius.Core.ShardInfo
  alias Mobius.Core.ShardList
  alias Mobius.Rest
  alias Mobius.Services.ETSShelf
  alias Mobius.Services.EventPipeline
  alias Mobius.Services.Shard

  require Logger

  @shards_table :mobius_shards

  @typep state :: %{
           client: Rest.Client.client(),
           token: String.t()
         }

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec list_shards :: [ShardInfo.t()]
  def list_shards do
    ShardList.list_shards(@shards_table)
  end

  @spec notify_ready(ShardInfo.t()) :: :ok
  def notify_ready(shard) do
    send(__MODULE__, {:shard_ready, shard})
    :ok
  end

  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    client = Rest.Client.new(token: token)

    state = %{
      client: client,
      token: token
    }

    :ok = ETSShelf.create_table(@shards_table, ShardList.table_options())

    client
    |> start_shards(token)
    |> Enum.each(&ShardList.add_shard(@shards_table, &1))

    {:ok, state}
  end

  def handle_info({:shard_ready, shard}, state) do
    Logger.debug("Shard #{inspect(shard)} is ready!")
    ShardList.update_shard_ready(@shards_table, shard)

    if ShardList.are_all_shards_ready?(@shards_table) do
      EventPipeline.notify_event("READY", nil)
    end

    {:noreply, state}
  end

  # TODO: Notify about all shards being ready?

  defp start_shards(client, token) do
    {:ok, bot_info} = Rest.Gateway.get_bot(client)
    url = parse_url(bot_info["url"])
    shard_count = bot_info["shards"]

    Logger.debug("Starting shards with #{inspect(bot_info)}")

    start_limit = Map.fetch!(bot_info, "session_start_limit")
    remaining = Map.fetch!(start_limit, "remaining")

    # Later we'll probably want to track this in ConnectionRatelimiter
    # To prevent issues where, without restarting the bot, too many connections are issued
    if remaining < shard_count do
      time_ms = Map.fetch!(start_limit, "reset_after")
      time_s = div(time_ms, 1000)
      warning = "Too many connections were issued with this token!"
      Logger.warn(warning <> " Waiting #{time_s} seconds...")
      Process.sleep(time_ms)
    end

    for shard <- ShardInfo.from_count(shard_count) do
      {:ok, pid} = Shard.start_shard(shard, url, token)
      Logger.debug("Started shard #{inspect(shard)} on #{inspect(pid)}")
      shard
    end
  end

  defp parse_url("wss://" <> url), do: url
end
