defmodule Mobius.Bot do
  @moduledoc """
  An interface for Discord API actions and events

  ## Synchronous and Asynchronous functions
  Unless specified otherwise, all functions in this module are synchronous and block the caller until the server has replied.
  This is mostly to provide backpressure and prevent the bot from being ratelimited unexpectedly.

  In the functions which *aren't* synchronous, the requests may be dropped to prevent exceeding the ratelimits of Discord.
  There will always be documentation about how dropped requests are signaled in those functions' documentation,
  but you can expect either `{:error, :ratelimited}` or a `Mobius.RatelimitError` exception.
  """

  @derive {Inspect, only: [:id]}
  defstruct [
    :shard_range,
    :id,
    :client,
    :ratelimit_server,
    :registry
  ]

  @type t :: %__MODULE__{
          shard_range: Range.t(),
          id: String.t(),
          client: Mobius.Api.Client.client(),
          registry: atom
        }

  import Bitwise
  import Mobius.Supervisor, only: [gateway_name: 2, pubsub_name: 0]
  import Mobius.Shard.EventProcessor, only: [bot_events_topic: 1]

  alias Mobius.PubSub
  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Shard.Gateway
  alias Mobius.Models.{Status, Snowflake}

  @typedoc "Return value for ratelimited asynchronous function calls"
  @type ratelimited :: {:error, :ratelimited}

  @doc """
  Starts the bot and returns a struct for manipulating it

  The struct isn't meant for direct usage or inspecting its values,
  consider it as a handle to your bot for further usage until it is stopped.
  The struct doesn't need to be updated during its lifetime since its values are all static.
  If you don't keep this struct, you won't be able to do anything with the bot.

  This function is not idempotent, two calls with the same arguments will not return the exact same struct.
  """
  @spec start_bot(atom, String.t()) :: Bot.t() | {:error, :unauthorized_token | :ratelimited}
  def start_bot(id, token) do
    # TODO: Figure out how to cleanup the ratelimit server in case of errors
    {:ok, ratelimit_server} = Mobius.Application.start_ratelimit_server()
    client = Client.new(token, ratelimit_server)

    with {:ok, info} <- Api.Gateway.get_bot(client) do
      shard_range = 0..(info.shards - 1)
      "wss://" <> url = info.url
      # TODO: Consider `info.session_start_limit` to prevent abuse
      bot = Mobius.Application.start_bot(shard_range, id, url, token)
      %__MODULE__{bot | client: client, ratelimit_server: ratelimit_server}
    end
  end

  @doc """
  Stops a started bot

  Returns `{:error, :not_found}` if the bot doesn't exist or isn't started.
  Returns `:ok` if the bot was successfully stopped.

  Note that after stopping a bot, using it for requests will raise errors

  ## Example

      iex> bot = start_bot(:my_bot, "valid tokens don't look like this")
      iex> :ok = stop_bot(bot)
  """
  @spec stop_bot(atom | Bot.t()) :: :ok | {:error, :not_found}
  def stop_bot(%__MODULE__{} = bot) do
    Mobius.Application.stop_ratelimit_server(bot.ratelimit_server)
    Mobius.Application.stop_bot(String.to_existing_atom(bot.id))
  end

  @doc """
  Returns the latest roundtrip time of each shard in an ordered list

  The nth element of the list is the ping of the nth shard
  """
  @spec get_pings(Bot.t()) :: list(pos_integer())
  def get_pings(bot) do
    for shard_num <- bot.shard_range do
      bot
      |> gateway_name(shard_num)
      |> Gateway.get_heartbeat_ping()
    end
  end

  @doc """
  Set the bot's new `Mobius.Models.Status`

  Returns an ordered list where the nth element is the return value of the nth shard

  **This function is asynchronous!** See the section `Synchronous vs Asynchronous` for details about what this means.

  This function may return `{:error, :ratelimited}` when the request is dropped.
  """
  @doc asynchronous: true
  @spec update_status(Bot.t(), Status.t()) :: [:ok | ratelimited()]
  def update_status(bot, %Status{} = status) do
    for shard <- bot.shard_range do
      gateway_name(bot, shard)
      |> Gateway.update_status(Status.serialize(status))
    end
  end

  @doc """
  Set the bot's new voice status in a specific guild

  Specifying a `channel_id` of `nil` will make the bot leave its voice channel in the specified guild.
  The bot can be in 0 or 1 voice channel per guild and can be in a voice channel in multiple guilds at once.

  **Important notice**: This does not initiate a voice server connection!
  While this library does not support voice server connections out of the box,
  one may implement such a feature by listening to [VOICE_SERVER_UPDATE](https://discord.com/developers/docs/topics/gateway#voice-server-update) events
  and following [Discord's voice connection protocol](https://discord.com/developers/docs/topics/voice-connections) properly.

  **This function is asynchronous!** See the section `Synchronous vs Asynchronous` for details about what this means.

  This function may return `{:error, :ratelimited}` when the request is dropped.
  """
  @doc asynchronous: true
  @spec update_voice_status(Bot.t(), Snowflake.t(), Snowflake.t() | nil, boolean, boolean) ::
          :ok | ratelimited()
  def update_voice_status(bot, guild_id, channel_id, self_deaf \\ false, self_mute \\ false)
      when is_integer(guild_id) do
    status = %{
      "guild_id" => snowflake_to_string(guild_id),
      "channel_id" => snowflake_to_string(channel_id),
      "self_mute" => self_mute,
      "self_deaf" => self_deaf
    }

    shard = shard_for_guild_id(guild_id, bot.shard_range)
    Gateway.update_voice_status(gateway_name(bot, shard), status)
  end

  @doc """
  Query the members of a guild by id

  `user_ids` can be either one user id snowflake or a list of user ids. You cannot request more than 100 user ids.

  This returns a `Stream` of [guild member objects](https://discord.com/developers/docs/resources/guild#guild-member-object) as maps with string keys.
  The resulting `Stream` may raise a `Mobius.TimeoutError` if Discord fails to send chunks quickly enough.
  It may also raise a `Mobius.RatelimitError` if this request would exceed Discord's ratelimits.

  **This function is asynchronous!** See the section `Synchronous vs Asynchronous` for details about what this means.

  As mentioned above, the resulting `Stream` may raise a `Mobius.RatelimitError` if it is dropped.
  Note that the exception is raised *when the stream is executed* and not when this function is called.
  This is to prevent requesting members without actually doing anything with them as this operation is expensive in populous guilds.

  In the following example, the line which would raise the exception is `usernames = Enum.to_list(stream)`.
  All lines before that one will *not* initiate the request and will *not* raise a `Mobius.RatelimitError` or a `Mobius.TimeoutError`.
  ```elixir
  stream = Bot.request_members(guild_id, user_ids, presences?)
  stream = Stream.map(stream, fn member -> member.user.username end)
  usernames = Enum.to_list(stream)
  ```
  """
  @doc asynchronous: true
  @spec request_members(Bot.t(), Snowflake.t(), Snowflake.t() | list(Snowflake.t()), boolean) ::
          term
  def request_members(bot, guild_id, user_ids, presences?) when is_integer(guild_id) do
    user_ids =
      cond do
        is_integer(user_ids) ->
          Integer.to_string(user_ids)

        is_list(user_ids) and Enum.all?(user_ids, &is_integer/1) ->
          Enum.map(user_ids, &Integer.to_string/1)

        true ->
          raise "User ids must be a single snowflake or a list of snowflakes"
      end

    Gateway.request_guild_members(
      gateway_name(bot, shard_for_guild_id(guild_id, bot.shard_range)),
      snowflake_to_string(guild_id),
      user_ids,
      presences?
    )
  end

  @doc """
  Query the members of a guild by prefix

  You may put an empty string for the prefix and a limit of 0 to request all members in the guild.
  The limit cannot be greater than 100. A limit of 0 and a non-empty prefix is also not allowed.

  This returns a `Stream` of [guild member objects](https://discord.com/developers/docs/resources/guild#guild-member-object) as maps with string keys.
  The resulting `Stream` may raise a `Mobius.TimeoutError` if Discord fails to send chunks quickly enough.
  It may also raise a `Mobius.RatelimitError` if this request would exceed Discord's ratelimits.

  **This function is asynchronous!** See the section `Synchronous vs Asynchronous` for details about what this means.

  As mentioned above, the resulting `Stream` may raise a `Mobius.RatelimitError` if it is dropped.
  Note that the exception is raised *when the stream is executed* and not when this function is called.
  This is to prevent requesting members without actually doing anything with them as this operation is expensive in populous guilds.

  In the following example, the line which would raise the exception is `usernames = Enum.to_list(stream)`.
  All lines before that one will *not* initiate the request and will *not* raise a `Mobius.RatelimitError` or a `Mobius.TimeoutError`.
  ```elixir
  stream = Bot.request_members(guild_id, "", 0, presences?)
  stream = Stream.map(stream, fn member -> member.user.username end)
  usernames = Enum.to_list(stream)
  ```
  """
  @doc asynchronous: true
  @spec request_members(Bot.t(), Snowflake.t(), String.t(), pos_integer(), boolean) :: term
  def request_members(bot, guild_id, prefix, limit, presences?)
      when is_integer(guild_id) and is_binary(prefix) and 0 <= limit and limit <= 100 do
    Gateway.request_guild_members(
      gateway_name(bot, shard_for_guild_id(guild_id, bot.shard_range)),
      snowflake_to_string(guild_id),
      prefix,
      limit,
      presences?
    )
  end

  @doc """
  Subscribe the caller process to the bot events

  The argument is a list of event name atoms for which to subscribe to.
  You will only receive events for which the event name is in this list.
  If you give an empty list, you will receive all events.

  The received events are in the form `{:EVENT_NAME, data}`.
  For a list of possible events and their data, refer to the official Discord documentation:
  https://discord.com/developers/docs/topics/gateway#commands-and-events
  Note that event names are all UPPER_CASE with underscores between words.
  The `data` part is usually a map with atom keys.

  You can subscribe multiple times, but you will receive duplicate events
  if there's an overlap in the allowed event names.
  """
  @spec subscribe_events(Bot.t(), [atom]) :: :ok
  def subscribe_events(bot, event_names) do
    PubSub.subscribe(pubsub_name(), bot_events_topic(bot.id), event_names)
  end

  @doc """
  Unsubscribe the caller process from all bot events

  If you used `subscribe_events/1` multiple times, this function
  will unsubscribe completely from all events regardless of the
  event names specified when subscribing.
  """
  @spec unsubscribe_events(Bot.t()) :: :ok
  def unsubscribe_events(bot) do
    PubSub.unsubscribe(pubsub_name(), bot_events_topic(bot.id))
  end

  defp snowflake_to_string(nil), do: nil
  defp snowflake_to_string(snowflake), do: Integer.to_string(snowflake)

  defp shard_for_guild_id(guild_id, shard_range) do
    rem(guild_id >>> 22, Enum.count(shard_range))
  end
end
