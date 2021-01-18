defmodule Mobius.Core.Intents do
  @moduledoc false

  alias Mobius.Core.Bitflags

  require Logger

  @type t :: MapSet.t(atom)

  # Order is important, use nil for missing bitflags
  @intents [
    :guilds,
    :guild_members,
    :guild_bans,
    :guild_emojis,
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

  # These are intents which must be enabled on the bot before being used
  @privileged [:guild_members, :guild_presences]

  # Must have at least one of the intents to receive the event
  @event_intents %{
    hello: [],
    ready: [],
    resumed: [],
    reconnect: [],
    invalid_session: [],
    channel_create: [:guilds],
    channel_update: [:guilds],
    channel_delete: [:guilds],
    channel_pins_update: [:guilds],
    guild_create: [:guilds],
    guild_update: [:guilds],
    guild_delete: [:guilds],
    guild_ban_add: [:guild_bans],
    guild_ban_remove: [:guild_bans],
    guild_emojis_update: [:guild_emojis],
    guild_integrations_update: [:guild_integrations],
    guild_member_add: [:guild_members],
    guild_member_remove: [:guild_members],
    guild_member_update: [:guild_members],
    guild_members_chunk: [],
    guild_role_create: [:guilds],
    guild_role_update: [:guilds],
    guild_role_delete: [:guilds],
    invite_create: [:guild_invites],
    invite_delete: [:guild_invites],
    message_create: [:guild_messages, :direct_messages],
    message_update: [:guild_messages, :direct_messages],
    message_delete: [:guild_messages, :direct_messages],
    message_delete_bulk: [:guild_messages, :direct_messages],
    message_reaction_add: [:guild_message_reactions, :direct_message_reactions],
    message_reaction_remove: [:guild_message_reactions, :direct_message_reactions],
    message_reaction_remove_all: [:guild_message_reactions, :direct_message_reactions],
    message_reaction_remove_emoji: [:guild_message_reactions, :direct_message_reactions],
    presence_update: [:guild_presences],
    typing_start: [:guild_message_typing, :direct_message_typing],
    user_update: [],
    voice_state_update: [:guild_voice_states],
    voice_server_update: [],
    webhooks_update: [:guild_webhooks]
  }

  @doc "Returns the set of all intents"
  @spec all_intents() :: t()
  def all_intents, do: MapSet.new(@intents)

  @doc """
  Converts an intents map to an integer of bitflags

  The integer follows what's specified in the Discord documentation:
  https://discord.com/developers/docs/topics/gateway#gateway-intents
  """
  @spec intents_to_integer(t()) :: integer
  def intents_to_integer(intents), do: Bitflags.create_bitflags(intents, @intents)

  @doc "Returns a set of privileged intents found in the given intents"
  @spec filter_privileged_intents(t()) :: t()
  def filter_privileged_intents(intents) do
    MapSet.intersection(intents, MapSet.new(@privileged))
  end

  @doc """
  Returns a list of events which can be received with the given intents

  Mostly useful for debugging
  """
  @spec events_for_intents(t()) :: list(atom)
  def events_for_intents(intents) do
    @event_intents
    |> Enum.map(fn {name, _} -> name end)
    |> Enum.filter(&has_intent_for_event?(&1, intents))
  end

  @doc "Returns true if the event can be received with the given intents. Returns false otherwise"
  @spec has_intent_for_event?(atom, t()) :: boolean
  def has_intent_for_event?(event_name, intents) do
    @event_intents
    |> Map.fetch!(event_name)
    |> check_has_intents(intents)
  end

  defp check_has_intents([], _intents), do: true
  defp check_has_intents(required, intents), do: Enum.any?(required, &Enum.member?(intents, &1))
end
