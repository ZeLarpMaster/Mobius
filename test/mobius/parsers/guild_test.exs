defmodule Mobius.Parsers.GuildTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_partial_guild/2" do
    raw = Samples.Guild.raw_guild(:partial)

    partial_guild = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"],
      icon: raw["icon"],
      features: [String.to_atom(String.downcase(hd(raw["features"])))],
      owner?: raw["owner"],
      permissions: raw["permissions"]
    }

    assert partial_guild == Parsers.Guild.parse_partial_guild(raw)
  end

  test "parse_guild/2 without required values" do
    %{}
    |> assert_missing_key("id", "v")
    |> Map.put("id", "123")
    |> assert_missing_key("name", "v")
    |> Map.put("name", "Cool Guild")
    |> assert_missing_key("icon", "v")
    |> Map.put("icon", "abcdef")
    |> assert_missing_key("splash", "v")
    |> Map.put("splash", "1337beef")
    |> assert_missing_key("discovery_splash", "v")
    |> Map.put("discovery_splash", "fed7")
    |> assert_missing_key("owner_id", "v")
    |> Map.put("owner_id", "456")
    |> assert_missing_key("region", "v")
    |> Map.put("region", "us-east")
    |> assert_missing_key("afk_channel_id", "v")
    |> Map.put("afk_channel_id", "147")
    |> assert_missing_key("afk_timeout", "v")
    |> Map.put("afk_timeout", 1800)
    |> assert_missing_key("verification_level", "v")
    |> Map.put("verification_level", 1)
    |> assert_missing_key("default_message_notifications", "v")
    |> Map.put("default_message_notifications", 1)
    |> assert_missing_key("explicit_content_filter", "v")
    |> Map.put("explicit_content_filter", 2)
    |> assert_missing_key("roles", "v")
    |> Map.put("roles", [])
    |> assert_missing_key("emojis", "v")
    |> Map.put("emojis", [])
    |> assert_missing_key("features", "v")
    |> Map.put("features", ["BANNER"])
    |> assert_missing_key("mfa_level", "v")
    |> Map.put("mfa_level", 1)
    |> assert_missing_key("application_id", "v")
    |> Map.put("application_id", "735240891253391360")
    |> assert_missing_key("system_channel_id", "v")
    |> Map.put("system_channel_id", "735240276502642848")
    |> assert_missing_key("system_channel_flags", "v")
    |> Map.put("system_channel_flags", 1)
    |> assert_missing_key("rules_channel_id", "v")
    |> Map.put("rules_channel_id", "735243513964527677")
    |> assert_missing_key("vanity_url_code", "v")
    |> Map.put("vanity_url_code", "myserver")
    |> assert_missing_key("description", "v")
    |> Map.put("description", "The great server")
    |> assert_missing_key("banner", "v")
    |> Map.put("banner", "ba300e2")
    |> assert_missing_key("premium_tier", "v")
    |> Map.put("premium_tier", 3)
    |> assert_missing_key("preferred_locale", "v")
    |> Map.put("preferred_locale", "en-US")
    |> assert_missing_key("public_updates_channel_id", "v")
    |> Map.put("public_updates_channel_id", "735241478032326698")
    |> Parsers.Guild.parse_guild()
    |> is_map()
    |> assert
  end

  test "parse_guild/2 with minimum" do
    raw = Samples.Guild.raw_guild(:minimal)

    guild = %{
      system_channel_id: Parsers.Utils.parse_snowflake(raw["system_channel_id"]),
      premium_tier: raw["premium_tier"],
      system_channel_flags: [:suppress_premium_subscriptions, :suppress_join_notifications],
      discovery_splash: raw["discovery_splash"],
      application_id: Parsers.Utils.parse_snowflake(raw["application_id"]),
      owner_id: Parsers.Utils.parse_snowflake(raw["owner_id"]),
      banner: raw["banner"],
      features: [:verified],
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      public_updates_channel_id: Parsers.Utils.parse_snowflake(raw["public_updates_channel_id"]),
      verification_level: :very_high,
      roles: Parsers.Role.parse_role(raw["roles"]),
      splash: raw["splash"],
      afk_timeout_s: raw["afk_timeout"],
      vanity_url_code: raw["vanity_url_code"],
      icon: raw["icon"],
      emojis: raw["emojis"],
      preferred_locale: raw["preferred_locale"],
      region: raw["region"],
      explicit_content_filter: :all_members,
      rules_channel_id: Parsers.Utils.parse_snowflake(raw["rules_channel_id"]),
      default_message_notifications: :only_mentions,
      name: raw["name"],
      description: raw["description"],
      mfa_level: :elevated,
      afk_channel_id: Parsers.Utils.parse_snowflake(raw["afk_channel_id"])
    }

    assert guild == Parsers.Guild.parse_guild(raw)
  end

  test "parse_guild/2 with everything" do
    raw = Samples.Guild.raw_guild(:full)

    guild = %{
      widget_channel_id: Parsers.Utils.parse_snowflake(raw["widget_channel_id"]),
      system_channel_id: Parsers.Utils.parse_snowflake(raw["system_channel_id"]),
      premium_tier: 3,
      system_channel_flags: [:suppress_premium_subscriptions, :suppress_join_notifications],
      discovery_splash: raw["discovery_splash"],
      application_id: Parsers.Utils.parse_snowflake(raw["application_id"]),
      owner?: false,
      owner_id: Parsers.Utils.parse_snowflake(raw["owner_id"]),
      banner: raw["banner"],
      features: [:verified],
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      public_updates_channel_id: Parsers.Utils.parse_snowflake(raw["public_updates_channel_id"]),
      verification_level: :very_high,
      permissions: raw["permissions"],
      roles: Parsers.Role.parse_role(raw["roles"]),
      splash: raw["splash"],
      afk_timeout_s: raw["afk_timeout"],
      vanity_url_code: raw["vanity_url_code"],
      icon: raw["icon"],
      emojis: raw["emojis"],
      max_video_channel_users: 25,
      preferred_locale: raw["preferred_locale"],
      region: raw["region"],
      explicit_content_filter: :all_members,
      rules_channel_id: Parsers.Utils.parse_snowflake(raw["rules_channel_id"]),
      default_message_notifications: :only_mentions,
      name: raw["name"],
      max_members: raw["max_members"],
      widget_enabled?: true,
      description: raw["description"],
      premium_subscription_count: raw["premium_subscription_count"],
      mfa_level: :elevated,
      afk_channel_id: Parsers.Utils.parse_snowflake(raw["afk_channel_id"]),
      max_presences: raw["max_presences"],
      joined_at: Parsers.Utils.parse_iso8601(raw["joined_at"]),
      large?: true,
      unavailable?: false,
      member_count: raw["member_count"],
      voice_states: raw["voice_states"],
      members: raw["members"],
      channels: Parsers.Channel.parse_channel(raw["channels"]),
      presences: raw["presences"],
      approximate_member_count: raw["approximate_member_count"],
      approximate_presence_count: raw["approximate_presence_count"]
    }

    assert guild == Parsers.Guild.parse_guild(raw)
  end

  defp assert_missing_key(map, key, path) do
    assert {:error, {:missing_key, key, path}} == Parsers.Guild.parse_guild(map)
    map
  end
end
