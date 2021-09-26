defmodule Mobius.Core.Event do
  @moduledoc false

  alias Mobius.Core.ShardInfo
  alias Mobius.Model
  alias Mobius.Models

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
    :webhooks_update,
    :application_command_create,
    :application_command_update,
    :application_command_delete,
    :interaction_create
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
          | :application_command_create
          | :application_command_update
          | :application_command_delete
          | :interaction_create

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
  def parse_data(name, data) when name in [:channel_create, :channel_update, :channel_delete] do
    Models.Channel.parse(data)
  end

  def parse_data(name, data) when name in [:guild_create, :guild_update, :guild_delete] do
    Models.Guild.parse(data)
  end

  def parse_data(name, data) when name in [:message_create, :message_update] do
    Models.Message.parse(data)
  end

  def parse_data(:user_update, data) do
    Models.User.parse(data)
  end

  def parse_data(:presence_update, data) do
    Models.Presence.parse(data)
  end

  def parse_data(:voice_state_update, data) do
    Models.VoiceState.parse(data)
  end

  def parse_data(:ready, data) do
    %{}
    |> add_field(data, :v)
    |> add_field(data, :user, &Models.User.parse/1)
    |> add_field(data, :private_channels)
    |> add_field(data, :guilds, &parse_guilds/1)
    |> add_field(data, :session_id)
    |> add_field(data, :shard, &ShardInfo.from_list/1)
    |> add_field(data, :application, &Models.Application.parse/1)
  end

  def parse_data(:channel_pins_update, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :last_pin_timestamp, &Models.Timestamp.parse/1)
  end

  def parse_data(name, data)
      when name in [:guild_ban_add, :guild_ban_remove, :guild_member_remove] do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :user, &Models.User.parse/1)
  end

  def parse_data(:guild_emojis_update, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :emojis, &parse_emojis/1)
  end

  def parse_data(:guild_integrations_update, data) do
    add_field(%{}, data, :guild_id, &Models.Snowflake.parse/1)
  end

  def parse_data(:guild_member_add, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> Map.put(:member, Models.Member.parse(data))
  end

  def parse_data(:guild_member_update, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :roles, &parse_snowflakes/1)
    |> add_field(data, :user, &Models.User.parse/1)
    |> add_field(data, :nick)
    |> add_field(data, :joined_at, &Models.Timestamp.parse/1)
    |> add_field(data, :premium_since, &Models.Timestamp.parse/1)
    |> add_field(data, :pending)
  end

  def parse_data(name, data) when name in [:guild_role_create, :guild_role_update] do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :role, &Models.Role.parse/1)
  end

  def parse_data(:guild_role_delete, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :role_id, &Models.Snowflake.parse/1)
  end

  def parse_data(:invite_create, data) do
    %{}
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :code)
    |> add_field(data, :created_at, &Models.Timestamp.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :inviter, &Models.User.parse/1)
    |> add_field(data, :max_age)
    |> add_field(data, :max_uses)
    |> add_field(data, :target_user, &Models.User.parse/1)
    |> add_field(data, :target_user_type, &Models.Invite.parse_type/1)
    |> add_field(data, :temporary)
    |> add_field(data, :uses)
  end

  def parse_data(:invite_delete, data) do
    %{}
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :code)
  end

  def parse_data(:message_delete, data) do
    %{}
    |> add_field(data, :id, &Models.Snowflake.parse/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
  end

  def parse_data(:message_delete_bulk, data) do
    %{}
    |> add_field(data, :ids, &parse_snowflakes/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
  end

  def parse_data(:message_reaction_add, data) do
    %{}
    |> add_field(data, :user_id, &Models.Snowflake.parse/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :message_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :member, &Models.Member.parse/1)
    |> add_field(data, :emoji, &Models.Emoji.parse/1)
  end

  def parse_data(:message_reaction_remove, data) do
    %{}
    |> add_field(data, :user_id, &Models.Snowflake.parse/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :message_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :emoji, &Models.Emoji.parse/1)
  end

  def parse_data(:message_reaction_remove_all, data) do
    %{}
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :message_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
  end

  def parse_data(:message_reaction_remove_emoji, data) do
    %{}
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :message_id, &Models.Snowflake.parse/1)
    |> add_field(data, :emoji, &Models.Emoji.parse/1)
  end

  def parse_data(:typing_start, data) do
    %{}
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :user_id, &Models.Snowflake.parse/1)
    |> add_field(data, :timestamp, &Models.Timestamp.parse_unix/1)
    |> add_field(data, :member, &Models.Member.parse/1)
  end

  def parse_data(:voice_server_update, data) do
    %{}
    |> add_field(data, :token)
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :endpoint)
  end

  def parse_data(:webhooks_update, data) do
    %{}
    |> add_field(data, :guild_id, &Models.Snowflake.parse/1)
    |> add_field(data, :channel_id, &Models.Snowflake.parse/1)
  end

  def parse_data(name, data)
      when name in [
             :application_command_create,
             :application_command_update,
             :application_command_delete
           ] do
    # TODO: Models.ApplicationCommand.parse(data)
    data
  end

  def parse_data(:interaction_create, data) do
    # TODO: Models.Interaction.parse(data)
    data
  end

  def parse_data(name, _) when name in @valid_names, do: nil

  defp add_field(map, values, key, parser \\ fn x -> x end)

  defp add_field(map, values, key, parser) when is_map(values) do
    value =
      values
      |> Map.get(Atom.to_string(key))
      |> parser.()

    Map.put(map, key, value)
  end

  defp add_field(map, _, _, _), do: map

  defp parse_guilds(data), do: Model.parse_list(data, &Models.Guild.parse/1)
  defp parse_emojis(data), do: Model.parse_list(data, &Models.Emoji.parse/1)
  defp parse_snowflakes(data), do: Model.parse_list(data, &Models.Snowflake.parse/1)
end
