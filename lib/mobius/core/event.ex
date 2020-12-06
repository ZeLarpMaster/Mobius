defmodule Mobius.Core.Event do
  @moduledoc false

  @valid_names [
    "CHANNEL_CREATE",
    "CHANNEL_UPDATE",
    "CHANNEL_DELETE",
    "CHANNEL_PINS_UPDATE",
    "GUILD_CREATE",
    "GUILD_UPDATE",
    "GUILD_DELETE",
    "GUILD_BAN_ADD",
    "GUILD_BAN_REMOVE",
    "GUILD_EMOJIS_UPDATE",
    "GUILD_INTEGRATIONS_UPDATE",
    "GUILD_MEMBER_ADD",
    "GUILD_MEMBER_REMOVE",
    "GUILD_MEMBER_UPDATE",
    "GUILD_ROLE_CREATE",
    "GUILD_ROLE_UPDATE",
    "GUILD_ROLE_DELETE",
    "INVITE_CREATE",
    "INVITE_DELETE",
    "MESSAGE_CREATE",
    "MESSAGE_UPDATE",
    "MESSAGE_DELETE",
    "MESSAGE_DELETE_BULK",
    "MESSAGE_REACTION_ADD",
    "MESSAGE_REACTION_REMOVE",
    "MESSAGE_REACTION_REMOVE_ALL",
    "MESSAGE_REACTION_REMOVE_EMOJI",
    "PRESENCE_UPDATE",
    "TYPING_START",
    "USER_UPDATE",
    "VOICE_STATE_UPDATE",
    "VOICE_SERVER_UPDATE",
    "WEBHOOKS_UPDATE"
  ]

  @type names ::
          :CHANNEL_CREATE
          | :CHANNEL_UPDATE
          | :CHANNEL_DELETE
          | :CHANNEL_PINS_UPDATE
          | :GUILD_CREATE
          | :GUILD_UPDATE
          | :GUILD_DELETE
          | :GUILD_BAN_ADD
          | :GUILD_BAN_REMOVE
          | :GUILD_EMOJIS_UPDATE
          | :GUILD_INTEGRATIONS_UPDATE
          | :GUILD_MEMBER_ADD
          | :GUILD_MEMBER_REMOVE
          | :GUILD_MEMBER_UPDATE
          | :GUILD_ROLE_CREATE
          | :GUILD_ROLE_UPDATE
          | :GUILD_ROLE_DELETE
          | :INVITE_CREATE
          | :INVITE_DELETE
          | :MESSAGE_CREATE
          | :MESSAGE_UPDATE
          | :MESSAGE_DELETE
          | :MESSAGE_DELETE_BULK
          | :MESSAGE_REACTION_ADD
          | :MESSAGE_REACTION_REMOVE
          | :MESSAGE_REACTION_REMOVE_ALL
          | :MESSAGE_REACTION_REMOVE_EMOJI
          | :PRESENCE_UPDATE
          | :TYPING_START
          | :USER_UPDATE
          | :VOICE_STATE_UPDATE
          | :VOICE_SERVER_UPDATE
          | :WEBHOOKS_UPDATE

  @doc "Converts string event names to atoms if it's valid otherwise returns nil"
  @spec parse_name(String.t()) :: names() | nil
  def parse_name(name) when name in @valid_names, do: String.to_atom(name)
  def parse_name(_name), do: nil

  @spec parse_data(names(), any) :: any
  def parse_data(_name, data), do: data
end
