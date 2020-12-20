defmodule Mobius.Core.Event do
  @moduledoc false

  @valid_names [
    :READY,
    :CHANNEL_CREATE,
    :CHANNEL_UPDATE,
    :CHANNEL_DELETE,
    :CHANNEL_PINS_UPDATE,
    :GUILD_CREATE,
    :GUILD_UPDATE,
    :GUILD_DELETE,
    :GUILD_BAN_ADD,
    :GUILD_BAN_REMOVE,
    :GUILD_EMOJIS_UPDATE,
    :GUILD_INTEGRATIONS_UPDATE,
    :GUILD_MEMBER_ADD,
    :GUILD_MEMBER_REMOVE,
    :GUILD_MEMBER_UPDATE,
    :GUILD_ROLE_CREATE,
    :GUILD_ROLE_UPDATE,
    :GUILD_ROLE_DELETE,
    :INVITE_CREATE,
    :INVITE_DELETE,
    :MESSAGE_CREATE,
    :MESSAGE_UPDATE,
    :MESSAGE_DELETE,
    :MESSAGE_DELETE_BULK,
    :MESSAGE_REACTION_ADD,
    :MESSAGE_REACTION_REMOVE,
    :MESSAGE_REACTION_REMOVE_ALL,
    :MESSAGE_REACTION_REMOVE_EMOJI,
    :PRESENCE_UPDATE,
    :TYPING_START,
    :USER_UPDATE,
    :VOICE_STATE_UPDATE,
    :VOICE_SERVER_UPDATE,
    :WEBHOOKS_UPDATE
  ]
  @valid_string_names Enum.map(@valid_names, &Atom.to_string/1)

  @type name ::
          :READY
          | :CHANNEL_CREATE
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

  @doc "Converts string event names to atoms if it's valid. Returns `nil` otherwise."
  @spec parse_name(String.t()) :: name() | nil
  def parse_name(name) when name in @valid_string_names, do: String.to_existing_atom(name)
  def parse_name(_name), do: nil

  @doc "Returns true if the given name is a valid event name"
  @spec is_event_name?(atom) :: boolean
  def is_event_name?(name), do: name in @valid_names

  @doc """
  Parses the given data based on the event name

  This function is only implemented for valid event names (see `t:name/0` and `is_event_name?/1`)
  such that passing an invalid event name will raise an error to the caller

  If you are calling this function with potentially invalid event names,
  use `is_event_name?/1` to first make sure the event name is valid
  """
  @spec parse_data(name(), any) :: any
  def parse_data(name, data) when name in @valid_names, do: data
end
