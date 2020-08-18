defmodule Mobius.Parsers.Message do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Parsers.Utils

  @spec parse_message(Utils.input(), Utils.path()) :: Utils.result()
  def parse_message(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :channel_id, {:via, "channel_id", Utils, :parse_snowflake}},
      {:optional, :guild_id, {:via, "guild_id", Utils, :parse_snowflake}},
      {:required, :author, {:via, "author", Parsers.User, :parse_user}},
      {:required, :content, "content"},
      {:required, :timestamp, {:via, "timestamp", Utils, :parse_iso8601}},
      {:required, :edited_timestamp, {:via, "edited_timestamp", Utils, :parse_iso8601}},
      {:required, :tts?, "tts"},
      {:required, :mention_everyone?, "mention_everyone"},
      {:required, :mentions, "mentions"},
      {:required, :mention_roles, "mention_roles"},
      {:optional, :mention_channels, "mention_channels"},
      {:required, :attachments, "attachments"},
      {:required, :embeds, "embeds"},
      {:optional, :reactions, "reactions"},
      {:optional, :nonce, "nonce"},
      {:required, :pinned?, "pinned"},
      {:optional, :webhook_id, {:via, "webhook_id", Utils, :parse_snowflake}},
      {:required, :type, {:via, "type", __MODULE__, :parse_message_type}},
      {:optional, :flags, {:via, "flags", __MODULE__, :parse_message_flags}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_message_type(integer, Utils.path()) :: atom | integer
  def parse_message_type(0, _path), do: :default
  def parse_message_type(1, _path), do: :recipient_add
  def parse_message_type(2, _path), do: :recipient_remove
  def parse_message_type(3, _path), do: :call
  def parse_message_type(4, _path), do: :channel_name_change
  def parse_message_type(5, _path), do: :channel_icon_change
  def parse_message_type(6, _path), do: :channel_pinned_message
  def parse_message_type(7, _path), do: :guild_member_join
  def parse_message_type(8, _path), do: :user_premium_guild_subscription
  def parse_message_type(9, _path), do: :user_premium_guild_subscription_tier1
  def parse_message_type(10, _path), do: :user_premium_guild_subscription_tier2
  def parse_message_type(11, _path), do: :user_premium_guild_subscription_tier3
  def parse_message_type(12, _path), do: :channel_follow_add
  def parse_message_type(14, _path), do: :guild_discovery_disqualified
  def parse_message_type(15, _path), do: :guild_discovery_requalified
  def parse_message_type(type, _path), do: type

  @message_flags [:crossposted, :is_crosspost, :suppress_embeds, :source_message_deleted, :urgent]
  @spec parse_message_flags(integer, any) :: MapSet.t(atom)
  def parse_message_flags(num, _path), do: Utils.parse_flags(num, @message_flags)
end
