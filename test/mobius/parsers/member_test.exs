defmodule Mobius.Parsers.MemberTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_member/2 with the minimum" do
    raw = Samples.Member.raw_member(:minimal)

    member = %{
      nickname: raw["nick"],
      roles: [Parsers.Utils.parse_snowflake(hd(raw["roles"]))],
      joined_at: Parsers.Utils.parse_iso8601(raw["joined_at"]),
      deaf?: raw["deaf"],
      mute?: raw["mute"]
    }

    assert member == Parsers.Member.parse_member(raw)
  end

  test "parse_member/2 with everything" do
    raw = Samples.Member.raw_member(:full)

    member = %{
      user: Parsers.User.parse_user(raw["user"]),
      nickname: raw["nick"],
      roles: [Parsers.Utils.parse_snowflake(hd(raw["roles"]))],
      joined_at: Parsers.Utils.parse_iso8601(raw["joined_at"]),
      premium_since: Parsers.Utils.parse_iso8601(raw["premium_since"]),
      deaf?: raw["deaf"],
      mute?: raw["mute"]
    }

    assert member == Parsers.Member.parse_member(raw)
  end
end
