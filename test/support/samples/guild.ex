defmodule Mobius.Samples.Guild do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_guild(:partial | :minimal | :full) :: map
  def raw_guild(:partial) do
    %{
      "id" => "#{random_snowflake()}",
      "name" => random_hex(16),
      "icon" => random_hex(32),
      "features" => ["BANNER"],
      "owner" => true,
      "permissions" => :rand.uniform(2_000_000)
    }
  end

  def raw_guild(:minimal) do
    %{
      "system_channel_id" => "#{random_snowflake()}",
      "premium_tier" => 3,
      "system_channel_flags" => 3,
      "discovery_splash" => random_hex(32),
      "application_id" => "#{random_snowflake()}",
      "owner_id" => "#{random_snowflake()}",
      "banner" => random_hex(32),
      "features" => ["VERIFIED"],
      "id" => "#{random_snowflake()}",
      "public_updates_channel_id" => "#{random_snowflake()}",
      "verification_level" => 4,
      "roles" => [
        Samples.Role.raw_role(:everyone),
        Samples.Role.raw_role(:full)
      ],
      "splash" => random_hex(32),
      "afk_timeout" => :rand.uniform(3600),
      "vanity_url_code" => random_hex(16),
      "icon" => random_hex(32),
      "emojis" => [
        Samples.Emoji.raw_emoji(:full)
      ],
      "preferred_locale" => "en-US",
      "region" => "us-east",
      "explicit_content_filter" => 2,
      "rules_channel_id" => "#{random_snowflake()}",
      "default_message_notifications" => 1,
      "name" => random_hex(16),
      "description" => random_hex(64),
      "mfa_level" => 1,
      "afk_channel_id" => "#{random_snowflake()}"
    }
  end

  def raw_guild(:full) do
    %{
      "widget_channel_id" => "#{random_snowflake()}",
      "owner" => false,
      "permissions" => :rand.uniform(2_000_000),
      "max_video_channel_users" => 25,
      "max_members" => 250_000,
      "widget_enabled" => true,
      "premium_subscription_count" => 42,
      "max_presences" => 75000,
      "joined_at" => Samples.Other.iso8601(),
      "large" => true,
      "unavailable" => false,
      "member_count" => 210_190,
      "voice_states" => [
        %{
          "channel_id" => "#{random_snowflake()}",
          "user_id" => "#{random_snowflake()}",
          "session_id" => random_hex(32),
          "deaf" => false,
          "mute" => false,
          "self_deaf" => false,
          "self_mute" => true,
          "suppress" => false
        }
      ],
      "members" => [Samples.Member.raw_member(:full)],
      "channels" => [Samples.Channel.raw_channel(:full)],
      "presences" => [Samples.Presence.raw_presence(:full)],
      "approximate_member_count" => :rand.uniform(500_000),
      "approximate_presence_count" => :rand.uniform(100_000)
    }
    |> Map.merge(raw_guild(:minimal))
  end
end
