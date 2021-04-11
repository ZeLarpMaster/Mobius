defmodule Mobius.Services.Bot do
  @moduledoc false

  use GenServer

  alias Mobius.Core.Intents
  alias Mobius.Core.ShardInfo
  alias Mobius.Core.ShardList
  alias Mobius.Rest
  alias Mobius.Services.ETSShelf
  alias Mobius.Services.Shard

  require Logger

  @default_prefix Application.compile_env(:mobius, :default_global_prefix, "!")

  @shards_table :mobius_shards

  @typep state :: %{
           token: String.t()
         }

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the list of shards currently running"
  @spec list_shards :: [ShardInfo.t()]
  def list_shards do
    ShardList.list_shards(@shards_table)
  end

  @doc "Returns true if any of the shards are ready. Returns false otherwise"
  @spec ready?() :: boolean
  def ready? do
    ShardList.is_any_shard_ready?(@shards_table)
  end

  @doc """
  Returns the current `Mobius.Core.Intents` of the bot

  This may raise a `KeyError` if this service isn't started yet
  """
  @spec get_intents! :: Intents.t()
  def get_intents! do
    __MODULE__
    |> :persistent_term.get(%{})
    |> Map.fetch!(:intents)
  end

  @doc """
  Returns the current `Mobius.Rest.Client` of the bot

  This may raise a `KeyError` if this service isn't started yet
  """
  @spec get_client!() :: Rest.Client.t()
  def get_client! do
    __MODULE__
    |> :persistent_term.get(%{})
    |> Map.fetch!(:client)
  end

  @doc """
  Returns the current global command prefix of the bot

  This command prefix is the default prefix for guilds which didn't set one
  and for commands sent to the bot in private messages.

  This may raise a `KeyError` if this service isn't started yet
  """
  def get_global_prefix! do
    __MODULE__
    |> :persistent_term.get(%{})
    |> Map.fetch!(:global_prefix)
  end

  @doc """
  Notifies Bot about the shard being ready

  This function is meant for internal use by the shards and nothing else
  """
  @spec notify_ready(ShardInfo.t()) :: :ok
  def notify_ready(shard) do
    send(__MODULE__, {:shard_ready, shard})
    :ok
  end

  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    intents = Keyword.fetch!(opts, :intents)
    token = Keyword.fetch!(opts, :token)
    client = Rest.Client.new(token: token)

    :ok = ETSShelf.create_table(@shards_table, ShardList.table_options())

    # Infrequent writes and very frequent reads make :persistent_term appropriate
    # Both are regrouped in one term as recommended in the :persistent_term's best practices:
    # > Prefer creating a few large persistent terms to creating many small persistent terms
    # https://erlang.org/doc/man/persistent_term.html#best-practices-for-using-persistent-terms
    :persistent_term.put(__MODULE__, %{
      client: client,
      intents: intents,
      global_prefix: @default_prefix
    })

    client
    |> start_shards(token, intents)
    |> Enum.each(&ShardList.add_shard(@shards_table, &1))

    {:ok, %{token: token}}
  end

  def handle_info({:shard_ready, shard}, state) do
    Logger.debug("Shard #{inspect(shard)} is ready!")
    ShardList.update_shard_ready(@shards_table, shard)

    {:noreply, state}
  end

  defp start_shards(client, token, intents) do
    {:ok, bot_info} = Rest.Gateway.get_bot(client)
    url = parse_url(bot_info.url)
    shard_count = bot_info.shards

    Logger.debug("Starting shards with #{inspect(bot_info)}")

    limit = bot_info.session_start_limit
    remaining = limit.remaining

    # Later we'll probably want to track this in ConnectionRatelimiter
    # To prevent issues where, without restarting the bot, too many connections are issued
    if remaining < shard_count do
      time_ms = limit.reset_after
      warning = "Too many connections were issued with this token!"
      Logger.warn(warning <> " Waiting #{time_ms} milliseconds...")
      Process.sleep(time_ms)
    end

    for shard <- ShardInfo.from_count(shard_count) do
      {:ok, pid} = Shard.start_shard(shard, url: url, token: token, intents: intents)
      Logger.debug("Started shard #{inspect(shard)} on #{inspect(pid)}")
      shard
    end
  end

  defp parse_url("wss://" <> url), do: url
end
