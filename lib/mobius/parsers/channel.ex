defmodule Mobius.Parsers.Channel do
  @moduledoc false

  alias Mobius.Parsers.Utils

  @spec parse_channel(Utils.input(), Utils.path()) :: Utils.result()
  def parse_channel(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :type, {:via, "type", __MODULE__, :parse_channel_type}},
      {:optional, :guild_id, {:via, "guild_id", Utils, :parse_snowflake}},
      {:optional, :position, "position"},
      {:optional, :permissions, {:via, "permission_overwrites", __MODULE__, :parse_overwrite}},
      {:optional, :name, "name"},
      {:optional, :topic, "topic"},
      {:optional, :nsfw?, "nsfw"},
      {:optional, :last_message_id, {:via, "last_message_id", Utils, :parse_snowflake}},
      {:optional, :bitrate, "bitrate"},
      {:optional, :user_limit, "user_limit"},
      {:optional, :slowmode_s, "rate_limit_per_user"},
      {:optional, :recipients, "recipients"},
      {:optional, :icon, "icon"},
      {:optional, :owner_id, {:via, "owner_id", Utils, :parse_snowflake}},
      {:optional, :application_id, {:via, "application_id", Utils, :parse_snowflake}},
      {:optional, :parent_id, {:via, "parent_id", Utils, :parse_snowflake}},
      {:optional, :last_pin_timestamp, {:via, "last_pin_timestamp", Utils, :parse_iso8601}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_channel_type(integer, Utils.path()) :: atom | integer
  def parse_channel_type(0, _path), do: :guild_text
  def parse_channel_type(1, _path), do: :dm
  def parse_channel_type(2, _path), do: :guild_voice
  def parse_channel_type(3, _path), do: :group_dm
  def parse_channel_type(4, _path), do: :guild_category
  def parse_channel_type(5, _path), do: :guild_news
  def parse_channel_type(6, _path), do: :guild_store
  def parse_channel_type(type, _path), do: type

  @spec parse_overwrite(Utils.input(), Utils.path()) :: Utils.result()
  def parse_overwrite(value, path) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :type, "type"},
      {:required, :allow, "allow"},
      {:required, :deny, "deny"}
    ]
    |> Utils.parse(value, path)
  end
end
