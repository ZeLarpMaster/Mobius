defmodule Mobius.Models.GuildTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Model
  alias Mobius.Models.Channel
  alias Mobius.Models.Emoji
  alias Mobius.Models.Guild
  alias Mobius.Models.Member
  alias Mobius.Models.Permissions
  alias Mobius.Models.Presence
  alias Mobius.Models.Role
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.VoiceState

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Guild.parse("string")
      assert nil == Guild.parse(42)
      assert nil == Guild.parse(true)
      assert nil == Guild.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Guild.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:icon, nil)
      |> assert_field(:icon_hash, nil)
      |> assert_field(:splash, nil)
      |> assert_field(:discovery_splash, nil)
      |> assert_field(:owner, nil)
      |> assert_field(:owner_id, nil)
      |> assert_field(:permissions, nil)
      |> assert_field(:region, nil)
      |> assert_field(:afk_channel_id, nil)
      |> assert_field(:afk_timeout, nil)
      |> assert_field(:widget_enabled, nil)
      |> assert_field(:widget_channel_id, nil)
      |> assert_field(:verification_level, nil)
      |> assert_field(:default_message_notifications, nil)
      |> assert_field(:explicit_content_filter, nil)
      |> assert_field(:roles, nil)
      |> assert_field(:emojis, nil)
      |> assert_field(:features, nil)
      |> assert_field(:mfa_level, nil)
      |> assert_field(:application_id, nil)
      |> assert_field(:system_channel_id, nil)
      |> assert_field(:system_channel_flags, nil)
      |> assert_field(:rules_channel_id, nil)
      |> assert_field(:joined_at, nil)
      |> assert_field(:large, nil)
      |> assert_field(:unavailable, nil)
      |> assert_field(:member_count, nil)
      |> assert_field(:voice_states, nil)
      |> assert_field(:members, nil)
      |> assert_field(:channels, nil)
      |> assert_field(:presences, nil)
      |> assert_field(:max_presences, nil)
      |> assert_field(:max_members, nil)
      |> assert_field(:vanity_url_code, nil)
      |> assert_field(:description, nil)
      |> assert_field(:banner, nil)
      |> assert_field(:premium_tier, nil)
      |> assert_field(:premium_subscription_count, nil)
      |> assert_field(:preferred_locale, nil)
      |> assert_field(:public_updates_channel_id, nil)
      |> assert_field(:max_video_channel_users, nil)
      |> assert_field(:approximate_member_count, nil)
      |> assert_field(:approximate_presence_count, nil)
      |> assert_field(:welcome_screen, nil)
    end

    test "parses all fields as expected" do
      map = guild()

      map
      |> Guild.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:icon, map["icon"])
      |> assert_field(:icon_hash, map["icon_hash"])
      |> assert_field(:splash, map["splash"])
      |> assert_field(:discovery_splash, map["discovery_splash"])
      |> assert_field(:owner, map["owner"])
      |> assert_field(:owner_id, Snowflake.parse(map["owner_id"]))
      |> assert_field(:permissions, Permissions.parse(map["permissions"]))
      |> assert_field(:region, map["region"])
      |> assert_field(:afk_channel_id, Snowflake.parse(map["afk_channel_id"]))
      |> assert_field(:afk_timeout, map["afk_timeout"])
      |> assert_field(:widget_enabled, map["widget_enabled"])
      |> assert_field(:widget_channel_id, Snowflake.parse(map["widget_channel_id"]))
      |> assert_field(:verification_level, :high)
      |> assert_field(:default_message_notifications, :only_mentions)
      |> assert_field(:explicit_content_filter, :members_without_roles)
      |> assert_field(:roles, Model.parse_list(map["roles"], &Role.parse/1))
      |> assert_field(:emojis, Model.parse_list(map["emojis"], &Emoji.parse/1))
      |> assert_field(:features, MapSet.new([:community, :welcome_screen_enabled]))
      |> assert_field(:mfa_level, :elevated)
      |> assert_field(:application_id, Snowflake.parse(map["application_id"]))
      |> assert_field(:system_channel_id, Snowflake.parse(map["system_channel_id"]))
      |> assert_field(
        :system_channel_flags,
        MapSet.new([:suppress_join_notifications, :suppress_premium_subscriptions])
      )
      |> assert_field(:rules_channel_id, Snowflake.parse(map["rules_channel_id"]))
      |> assert_field(:joined_at, Timestamp.parse(map["joined_at"]))
      |> assert_field(:large, map["large"])
      |> assert_field(:unavailable, map["unavailable"])
      |> assert_field(:member_count, map["member_count"])
      |> assert_field(:voice_states, Model.parse_list(map["voice_states"], &VoiceState.parse/1))
      |> assert_field(:members, Model.parse_list(map["members"], &Member.parse/1))
      |> assert_field(:channels, Model.parse_list(map["channels"], &Channel.parse/1))
      |> assert_field(:presences, Model.parse_list(map["presences"], &Presence.parse/1))
      |> assert_field(:max_presences, map["max_presences"])
      |> assert_field(:max_members, map["max_members"])
      |> assert_field(:vanity_url_code, map["vanity_url_code"])
      |> assert_field(:description, map["description"])
      |> assert_field(:banner, map["banner"])
      |> assert_field(:premium_tier, :tier_1)
      |> assert_field(:premium_subscription_count, map["premium_subscription_count"])
      |> assert_field(:preferred_locale, map["preferred_locale"])
      |> assert_field(
        :public_updates_channel_id,
        Snowflake.parse(map["public_updates_channel_id"])
      )
      |> assert_field(:max_video_channel_users, map["max_video_channel_users"])
      |> assert_field(:approximate_member_count, map["approximate_member_count"])
      |> assert_field(:approximate_presence_count, map["approximate_presence_count"])
      |> assert_field(:welcome_screen, Guild.WelcomeScreen.parse(map["welcome_screen"]))
    end
  end
end
