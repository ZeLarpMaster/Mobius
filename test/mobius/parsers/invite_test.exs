defmodule Mobius.Parsers.InviteTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_invite/2 with minimum" do
    raw = Samples.Invite.raw_invite(:minimal)

    invite = %{
      code: raw["code"],
      channel: Parsers.Channel.parse_channel(raw["channel"])
    }

    assert invite == Parsers.Invite.parse_invite(raw)
  end

  test "parse_invite/2" do
    raw = Samples.Invite.raw_invite(:full)

    invite = %{
      code: raw["code"],
      channel: Parsers.Channel.parse_channel(raw["channel"]),
      guild: Parsers.Invite.parse_invite_guild(raw["guild"]),
      inviter: Parsers.User.parse_user(raw["inviter"]),
      target_user: Parsers.User.parse_user(raw["target_user"]),
      target_user_type: :stream,
      approximate_presence_count: raw["approximate_presence_count"],
      approximate_member_count: raw["approximate_member_count"],
      uses: raw["uses"],
      max_uses: raw["max_uses"],
      max_age: raw["max_age"],
      temporary?: raw["temporary"],
      created_at: Parsers.Utils.parse_iso8601(raw["created_at"])
    }

    assert invite == Parsers.Invite.parse_invite(raw)
  end

  test "parse_invite_guild/2" do
    raw = Samples.Invite.raw_invite_guild(:full)

    invite_guild = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      banner: raw["banner"],
      description: raw["description"],
      icon: raw["icon"],
      name: raw["name"],
      splash: raw["splash"],
      vanity_url_code: raw["vanity_url_code"],
      verification_level: :high,
      features: MapSet.new([:public])
    }

    assert invite_guild == Parsers.Invite.parse_invite_guild(raw)
  end
end
