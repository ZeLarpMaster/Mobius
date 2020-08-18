defmodule Mobius.Parsers.MessageTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_message/2 with everything" do
    raw = Samples.Message.raw_message(:full)

    message = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      channel_id: Parsers.Utils.parse_snowflake(raw["channel_id"]),
      guild_id: Parsers.Utils.parse_snowflake(raw["guild_id"]),
      author: Parsers.User.parse_user(raw["author"]),
      content: raw["content"],
      timestamp: Parsers.Utils.parse_iso8601(raw["timestamp"]),
      edited_timestamp: Parsers.Utils.parse_iso8601(raw["edited_timestamp"]),
      tts?: false,
      mention_everyone?: false,
      mentions: [],
      mention_roles: [],
      mention_channels: [],
      attachments: [],
      embeds: [],
      reactions: [],
      nonce: raw["nonce"],
      pinned?: false,
      webhook_id: Parsers.Utils.parse_snowflake(raw["webhook_id"]),
      type: :default,
      flags: MapSet.new([:suppress_embeds])
    }

    assert message == Parsers.Message.parse_message(raw)
  end

  test "parse_message_flags/2" do
    assert Parsers.Message.parse_message_flags(31, "map") ==
             MapSet.new([
               :crossposted,
               :is_crosspost,
               :suppress_embeds,
               :source_message_deleted,
               :urgent
             ])
  end
end
