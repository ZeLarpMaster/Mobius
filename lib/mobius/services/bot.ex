defmodule Mobius.Services.Bot do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.ShardInfo
  alias Mobius.Rest
  alias Mobius.Services.Shard

  @shard_ready_timeout 10_000

  @typep state :: %{
           client: Rest.Client.client(),
           shards: [ShardInfo.t()],
           token: String.t()
         }

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec list_shards() :: [ShardInfo.t()]
  def list_shards do
    GenServer.call(__MODULE__, :list_shards)
  end

  @spec notify_ready(ShardInfo.t()) :: :ok
  def notify_ready(shard) do
    send(__MODULE__, {:shard_ready, shard})
    :ok
  end

  @spec init(keyword) :: {:ok, state(), {:continue, :start_shards}}
  def init(opts) do
    token = Keyword.fetch!(opts, :token)

    state = %{
      client: Rest.Client.new(token: token),
      shards: [],
      token: token
    }

    {:ok, state, {:continue, :start_shards}}
  end

  @spec handle_continue(:start_shards, state()) :: {:noreply, state()}
  def handle_continue(:start_shards, state) do
    {:ok, bot_info} = Rest.Gateway.get_bot(state.client)

    Logger.debug("Starting shards with #{inspect(bot_info)}")

    # TODO: Take into account bot_info["session_start_limit"]

    ShardInfo.from_count(bot_info["shards"])
    |> schedule_next_shards(parse_url(bot_info["url"]))

    {:noreply, state}
  end

  def handle_info({:start_shard, [shard | shards], url}, state) do
    {:ok, pid} = Shard.start_shard(shard, url, state.token)
    Logger.debug("Started shard #{inspect(shard)} on #{inspect(pid)}")
    await_shard_ready(shard)
    schedule_next_shards(shards, url)
    {:noreply, update_in(state.shards, &(&1 ++ [shard]))}
  end

  def handle_call(:list_shards, _from, state) do
    {:reply, state.shards, state}
  end

  defp await_shard_ready(shard) do
    receive do
      {:shard_ready, ^shard} -> Logger.debug("Shard #{inspect(shard)} is ready!")
    after
      @shard_ready_timeout -> Logger.warn("Shard #{inspect(shard)} was not ready in time!")
    end
  end

  # TODO: Notify about all shards being ready?
  defp schedule_next_shards([], _url), do: nil
  defp schedule_next_shards(shards, url), do: send(self(), {:start_shard, shards, url})

  defp parse_url("wss://" <> url), do: url
end
