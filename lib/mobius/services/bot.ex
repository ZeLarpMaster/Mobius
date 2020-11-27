defmodule Mobius.Services.Bot do
  @moduledoc false

  use GenServer

  alias Mobius.Core.ShardInfo
  alias Mobius.Rest
  alias Mobius.Services.ETSShelf
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
    [results] = :ets.match(@shards_table, {:"$1", :_})
    results
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

    :ok = ETSShelf.create_table(@shards_table, [:ordered_set, :protected])

    client
    |> start_shards(token)
    |> Enum.each(&store_shard/1)

    {:ok, state}
  end

  def handle_info({:shard_ready, shard}, state) do
    Logger.debug("Shard #{inspect(shard)} is ready!")
    update_shard_ready(shard)
    {:noreply, state}
  end

  # TODO: Notify about all shards being ready?

  defp start_shards(client, token) do
    {:ok, bot_info} = Rest.Gateway.get_bot(client)
    url = parse_url(bot_info["url"])

    Logger.debug("Starting shards with #{inspect(bot_info)}")

    # TODO: Take into account bot_info["session_start_limit"]

    for shard <- ShardInfo.from_count(bot_info["shards"]) do
      {:ok, pid} = Shard.start_shard(shard, url, token)
      Logger.debug("Started shard #{inspect(shard)} on #{inspect(pid)}")
      shard
    end
  end

  defp update_shard_ready(%ShardInfo{} = shard) do
    :ets.insert(@shards_table, {shard, :ready})
  end

  defp store_shard(%ShardInfo{} = shard) do
    :ets.insert(@shards_table, {shard, :starting})
  end

  defp parse_url("wss://" <> url), do: url
end
