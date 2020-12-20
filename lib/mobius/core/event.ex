defmodule Mobius.Core.Event do
  @moduledoc false

  @valid_names [
    :ready,
    :channel_create,
    :channel_update,
    :channel_delete,
    :channel_pins_update,
    :guild_create,
    :guild_update,
    :guild_delete,
    :guild_ban_add,
    :guild_ban_remove,
    :guild_emojis_update,
    :guild_integrations_update,
    :guild_member_add,
    :guild_member_remove,
    :guild_member_update,
    :guild_role_create,
    :guild_role_update,
    :guild_role_delete,
    :invite_create,
    :invite_delete,
    :message_create,
    :message_update,
    :message_delete,
    :message_delete_bulk,
    :message_reaction_add,
    :message_reaction_remove,
    :message_reaction_remove_all,
    :message_reaction_remove_emoji,
    :presence_update,
    :typing_start,
    :user_update,
    :voice_state_update,
    :voice_server_update,
    :webhooks_update
  ]
  @valid_string_names Enum.map(@valid_names, &String.upcase(Atom.to_string(&1)))

  @type name ::
          :ready
          | :channel_create
          | :channel_update
          | :channel_delete
          | :channel_pins_update
          | :guild_create
          | :guild_update
          | :guild_delete
          | :guild_ban_add
          | :guild_ban_remove
          | :guild_emojis_update
          | :guild_integrations_update
          | :guild_member_add
          | :guild_member_remove
          | :guild_member_update
          | :guild_role_create
          | :guild_role_update
          | :guild_role_delete
          | :invite_create
          | :invite_delete
          | :message_create
          | :message_update
          | :message_delete
          | :message_delete_bulk
          | :message_reaction_add
          | :message_reaction_remove
          | :message_reaction_remove_all
          | :message_reaction_remove_emoji
          | :presence_update
          | :typing_start
          | :user_update
          | :voice_state_update
          | :voice_server_update
          | :webhooks_update

  @doc "Converts string event names to atoms if it's valid. Returns `nil` otherwise."
  @spec parse_name(String.t()) :: name() | nil
  def parse_name(name) when name in @valid_string_names do
    String.to_existing_atom(String.downcase(name))
  end

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
