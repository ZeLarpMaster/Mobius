defmodule Mobius.Intents do
  @moduledoc false

  require Logger

  @type intents :: MapSet.t(atom)

  # Order is important, use nil for missing bitflags
  @intents [
    :guilds,
    :guild_members,
    :guild_bans,
    :guild_integrations,
    :guild_webhooks,
    :guild_invites,
    :guild_voice_states,
    :guild_presences,
    :guild_messages,
    :guild_message_reactions,
    :guild_message_typing,
    :direct_messages,
    :direct_message_reactions,
    :direct_message_typing
  ]

  @privileged [:guild_members, :guild_presences]

  # Must have at least one of the intents to receive the event
  @event_intents [
    HELLO: [],
    READY: [],
    RESUMED: [],
    RECONNECT: [],
    INVALID_SESSION: [],
    CHANNEL_CREATE: [:guilds],
    CHANNEL_UPDATE: [:guilds],
    CHANNEL_DELETE: [:guilds],
    CHANNEL_PINS_UPDATE: [:guilds],
    GUILD_CREATE: [:guilds],
    GUILD_UPDATE: [:guilds],
    GUILD_DELETE: [:guilds],
    GUILD_BAN_ADD: [:guild_bans],
    GUILD_BAN_REMOVE: [:guild_bans],
    GUILD_EMOJIS_UPDATE: [:guild_emojis],
    GUILD_INTEGRATIONS_UPDATE: [:guild_integrations],
    GUILD_MEMBER_ADD: [:guild_members],
    GUILD_MEMBER_REMOVE: [:guild_members],
    GUILD_MEMBER_UPDATE: [:guild_members],
    GUILD_MEMBERS_CHUNK: [],
    GUILD_ROLE_CREATE: [:guilds],
    GUILD_ROLE_UPDATE: [:guilds],
    GUILD_ROLE_DELETE: [:guilds],
    INVITE_CREATE: [:guild_invites],
    INVITE_DELETE: [:guild_invites],
    MESSAGE_CREATE: [:guild_messages, :direct_messages],
    MESSAGE_UPDATE: [:guild_messages, :direct_messages],
    MESSAGE_DELETE: [:guild_messages, :direct_messages],
    MESSAGE_DELETE_BULK: [:guild_messages, :direct_messages],
    MESSAGE_REACTION_ADD: [:guild_message_reactions, :direct_message_reactions],
    MESSAGE_REACTION_REMOVE: [:guild_message_reactions, :direct_message_reactions],
    MESSAGE_REACTION_REMOVE_ALL: [:guild_message_reactions, :direct_message_reactions],
    MESSAGE_REACTION_REMOVE_EMOJI: [:guild_message_reactions, :direct_message_reactions],
    PRESENCE_UPDATE: [:guild_presences],
    TYPING_START: [:guild_message_typing, :direct_message_typing],
    USER_UPDATE: [],
    VOICE_STATE_UPDATE: [:guild_voice_states],
    VOICE_SERVER_UPDATE: [],
    WEBHOOKS_UPDATE: [:guild_webhooks]
  ]

  @spec intents_to_integer(intents()) :: integer
  def intents_to_integer(intents), do: Mobius.Utils.create_bitflags(intents, @intents)

  @spec warn_privileged_intents(intents()) :: any
  def warn_privileged_intents(intents) do
    for intent <- @privileged, intent in intents do
      Logger.warn(
        "You are using the privileged intent #{inspect(intent)} but don't seem to have it enabled"
      )
    end
  end

  @spec has_intent_for_event?(atom, list(atom)) :: boolean
  def has_intent_for_event?(event_name, intents)

  for {event_name, required_intents} <- @event_intents do
    if required_intents == [] do
      def has_intent_for_event?(unquote(event_name), _intents), do: true
    else
      def has_intent_for_event?(unquote(event_name), intents) do
        Enum.any?(unquote(required_intents), &(&1 in intents))
      end
    end
  end
end
