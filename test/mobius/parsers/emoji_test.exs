defmodule Mobius.Parsers.EmojiTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_emoji/2 with minimal" do
    raw = Samples.Emoji.raw_emoji(:minimal)

    emoji = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"]
    }

    assert emoji == Parsers.Emoji.parse_emoji(raw)
  end

  test "parse_emoji/2" do
    raw = Samples.Emoji.raw_emoji(:full)

    emoji = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"],
      role_ids: Enum.map(raw["roles"], &Parsers.Utils.parse_snowflake/1),
      user: Parsers.User.parse_user(raw["user"]),
      require_colons?: raw["require_colons"],
      managed?: raw["managed"],
      animated?: raw["animated"],
      available?: raw["available"]
    }

    assert emoji == Parsers.Emoji.parse_emoji(raw)
  end
end
