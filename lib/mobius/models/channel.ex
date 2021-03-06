defmodule Mobius.Models.Channel do
  @moduledoc """
  Struct for Discord's Channel

  Related documentation:
  https://discord.com/developers/docs/resources/channel#channel-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.PermissionsOverwrite
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  defstruct [
    :id,
    :type,
    :guild_id,
    :position,
    :permission_overwrites,
    :name,
    :topic,
    :nsfw,
    :last_message_id,
    :bitrate,
    :user_limit,
    :rate_limit_per_user,
    :recipients,
    :icon,
    :owner_id,
    :application_id,
    :parent_id,
    :last_pin_timestamp
  ]

  @type type ::
          :guild_text
          | :dm
          | :guild_voice
          | :group_dm
          | :guild_category
          | :guild_news
          | :guild_store

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          type: type(),
          guild_id: Snowflake.t() | nil,
          position: non_neg_integer() | nil,
          permission_overwrites: [PermissionsOverwrite.t()] | nil,
          name: String.t() | nil,
          topic: String.t() | nil,
          nsfw: boolean | nil,
          last_message_id: Snowflake.t() | nil,
          bitrate: non_neg_integer() | nil,
          user_limit: non_neg_integer() | nil,
          rate_limit_per_user: non_neg_integer() | nil,
          recipients: [User.t()] | nil,
          icon: String.t() | nil,
          owner_id: Snowflake.t() | nil,
          application_id: Snowflake.t() | nil,
          parent_id: Snowflake.t() | nil,
          last_pin_timestamp: DateTime.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :position)
    |> add_field(map, :permission_overwrites, &parse_overwrites/1)
    |> add_field(map, :name)
    |> add_field(map, :topic)
    |> add_field(map, :nsfw)
    |> add_field(map, :last_message_id, &Snowflake.parse/1)
    |> add_field(map, :bitrate)
    |> add_field(map, :user_limit)
    |> add_field(map, :rate_limit_per_user)
    |> add_field(map, :recipients, &parse_recipients/1)
    |> add_field(map, :icon)
    |> add_field(map, :owner_id, &Snowflake.parse/1)
    |> add_field(map, :application_id, &Snowflake.parse/1)
    |> add_field(map, :parent_id, &Snowflake.parse/1)
    |> add_field(map, :last_pin_timestamp, &Timestamp.parse/1)
  end

  def parse(_), do: nil

  # Not private for other models which may need to parse channel types (ex.: ChannelMention)
  def parse_type(0), do: :guild_text
  def parse_type(1), do: :dm
  def parse_type(2), do: :guild_voice
  def parse_type(3), do: :group_dm
  def parse_type(4), do: :guild_category
  def parse_type(5), do: :guild_news
  def parse_type(6), do: :guild_store
  def parse_type(_), do: nil

  defp parse_overwrites(overwrites), do: parse_list(overwrites, &PermissionsOverwrite.parse/1)
  defp parse_recipients(recipients), do: parse_list(recipients, &User.parse/1)
end
