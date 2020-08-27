defmodule Mobius.Cache.Filler do
  @moduledoc false

  use GenServer

  import Mobius.Supervisor, only: [pubsub_name: 0]
  import Mobius.Shard.EventProcessor, only: [bot_events_topic: 1]

  require Logger

  alias Mobius.Cache
  alias Mobius.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl GenServer
  def init(opts) do
    bot_id = Keyword.fetch!(opts, :bot_id)

    state = %{
      bot_id: bot_id,
      cache: Keyword.fetch!(opts, :cache)
    }

    Process.link(Process.whereis(pubsub_name()))
    PubSub.subscribe(pubsub_name(), bot_events_topic(bot_id))

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:READY, ready}, state) do
    guilds = ready.guilds
    channels = ready.private_channels
    # presences = ready.presences
    me = ready.user

    Enum.each(guilds, &Cache.Guild.update_guild(state.cache, &1))
    Enum.each(channels, &Cache.Channel.update_channel(state.cache, &1))
    Cache.User.update_user(state.cache, me)
    {:noreply, state}
  end

  def handle_info({:GUILD_CREATE, guild}, state) do
    Cache.Guild.update_guild(state.cache, guild)
    {:noreply, state}
  end

  def handle_info({:MESSAGE_CREATE, message}, state) do
    Cache.Message.update_message(state.cache, message)
    Cache.User.update_user(state.cache, message.author)
    {:noreply, state}
  end

  def handle_info({event_name, _}, state) do
    Logger.debug("Unhandled filler event: #{event_name}")
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug("Unhandled event: #{inspect(event)}")
    {:noreply, state}
  end
end
