defmodule Mobius.Parsers.ChannelTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_channel/2 without required values" do
    assert {:error, {:missing_key, "id", "v"}} == Parsers.Channel.parse_channel(%{})

    assert {:error, {:missing_key, "type", "v"}} ==
             Parsers.Channel.parse_channel(%{"id" => "123"})
  end

  test "parse_channel/2 with minimum" do
    raw = Samples.Channel.raw_channel(:minimal)

    channel = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      type: :guild_text
    }

    assert channel == Parsers.Channel.parse_channel(raw)
  end

  test "parse_channel/2 with everything" do
    raw = Samples.Channel.raw_channel(:full)

    channel = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      type: :guild_text,
      guild_id: Parsers.Utils.parse_snowflake(raw["guild_id"]),
      position: raw["position"],
      permissions: [%{allow: 42, deny: 0, id: 456, type: "member"}],
      name: raw["name"],
      topic: raw["topic"],
      nsfw?: raw["nsfw"],
      last_message_id: Parsers.Utils.parse_snowflake(raw["last_message_id"]),
      bitrate: raw["bitrate"],
      user_limit: raw["user_limit"],
      slowmode_s: raw["rate_limit_per_user"],
      recipients: raw["recipients"],
      icon: raw["icon"],
      owner_id: Parsers.Utils.parse_snowflake(raw["owner_id"]),
      application_id: Parsers.Utils.parse_snowflake(raw["application_id"]),
      parent_id: Parsers.Utils.parse_snowflake(raw["parent_id"]),
      last_pin_timestamp: Parsers.Utils.parse_iso8601(raw["last_pin_timestamp"])
    }

    assert channel == Parsers.Channel.parse_channel(raw)
  end
end
