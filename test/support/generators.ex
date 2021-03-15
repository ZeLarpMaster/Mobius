defmodule Mobius.Generators do
  @moduledoc "Functions to generate models as given by Discord (as maps with strings as keys)"

  import Mobius.Fixtures

  def guild(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "name" => random_hex(16),
      "icon" => random_hex(32),
      "icon_hash" => random_hex(32),
      "splash" => random_hex(32),
      "discovery_splash" => random_hex(32),
      "owner" => true,
      "owner_id" => random_snowflake(),
      "permissions" => "#{:rand.uniform(0x7FFFFFFF)}",
      "region" => random_hex(8),
      "afk_channel_id" => random_snowflake(),
      "afk_timeout" => :rand.uniform(3600),
      "widget_enabled" => true,
      "widget_channel_id" => random_snowflake(),
      "verification_level" => 3,
      "default_message_notifications" => 1,
      "explicit_content_filter" => 1,
      "roles" => [role(), role()],
      "emojis" => [emoji(), emoji()],
      "features" => ["COMMUNITY", "WELCOME_SCREEN_ENABLED"],
      "mfa_level" => 1,
      "application_id" => random_snowflake(),
      "system_channel_id" => random_snowflake(),
      "system_channel_flags" => 0b11,
      "rules_channel_id" => random_snowflake(),
      "joined_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "large" => true,
      "unavailable" => false,
      "member_count" => :rand.uniform(15_000),
      "voice_states" => [voice_state(), voice_state()],
      "members" => [member(), member()],
      "channels" => [channel(), channel()],
      "presences" => [presence(), presence()],
      "max_presences" => :rand.uniform(1_000),
      "max_members" => :rand.uniform(300_000),
      "vanity_url_code" => random_hex(8),
      "description" => random_hex(32),
      "banner" => random_hex(32),
      "premium_tier" => 1,
      "premium_subscription_count" => :rand.uniform(14),
      "preferred_locale" => "en",
      "public_updates_channel_id" => random_snowflake(),
      "max_video_channel_users" => :rand.uniform(250),
      "approximate_member_count" => :rand.uniform(150_000),
      "approximate_presence_count" => :rand.uniform(500),
      "welcome_screen" => %{
        "description" => random_hex(16),
        "welcome_channels" => [
          %{
            "channel_id" => random_snowflake(),
            "description" => random_hex(8),
            "emoji_id" => random_snowflake(),
            "emoji_name" => random_hex(8)
          },
          %{
            "channel_id" => random_snowflake(),
            "description" => random_hex(8),
            "emoji_id" => random_snowflake(),
            "emoji_name" => random_hex(8)
          }
        ]
      }
    }

    merge_opts(defaults, opts)
  end

  @spec invite(keyword) :: map
  def invite(opts \\ []) do
    defaults = %{
      "code" => random_hex(16),
      "guild" => %{},
      "channel" => channel(),
      "inviter" => user(),
      "target_user" => user(),
      "target_user_type" => 1,
      "approximate_presence_count" => :rand.uniform(1000),
      "approximate_member_count" => :rand.uniform(10_000),
      "uses" => :rand.uniform(100),
      "max_uses" => :rand.uniform(1000),
      "max_age" => :rand.uniform(3600),
      "temporary" => true,
      "created_at" => DateTime.to_iso8601(DateTime.utc_now())
    }

    merge_opts(defaults, opts)
  end

  @spec channel(keyword) :: map
  def channel(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "type" => 0,
      "guild_id" => random_snowflake(),
      "position" => :rand.uniform(20),
      "permission_overwrites" => [
        %{
          "id" => random_snowflake(),
          "type" => 0,
          "allow" => "#{:rand.uniform(Bitwise.<<<(1, 30))}",
          "deny" => "#{:rand.uniform(Bitwise.<<<(1, 30))}"
        }
      ],
      "name" => random_hex(8),
      "topic" => random_hex(8),
      "nsfw" => false,
      "last_message_id" => random_snowflake(),
      "bitrate" => :rand.uniform(18) * 1000,
      "user_limit" => :rand.uniform(25),
      "rate_limit_per_user" => :rand.uniform(60 * 60 * 24),
      "recipients" => [user()],
      "icon" => random_hex(16),
      "owner_id" => random_snowflake(),
      "application_id" => random_snowflake(),
      "parent_id" => random_snowflake(),
      "last_pin_timestamp" => DateTime.to_iso8601(DateTime.utc_now())
    }

    merge_opts(defaults, opts)
  end

  @spec message(keyword) :: map
  def message(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "channel_id" => random_snowflake(),
      "guild_id" => random_snowflake(),
      "author" => user(),
      "member" => Map.delete(member(), "user"),
      "content" => random_hex(16),
      "timestamp" => DateTime.to_iso8601(DateTime.utc_now()),
      "edited_timestamp" => DateTime.to_iso8601(DateTime.utc_now()),
      "tts" => false,
      "mention_everyone" => true,
      "mentions" => Map.put(user(), "member", member()),
      "mention_roles" => [random_snowflake()],
      "mention_channels" => [
        %{
          "id" => random_snowflake(),
          "guild_id" => random_snowflake(),
          "type" => 0,
          "name" => random_hex(8)
        }
      ],
      "attachments" => [attachment()],
      "embeds" => [embed()],
      "reactions" => [%{"count" => :rand.uniform(5000), "me" => false, "emoji" => emoji()}],
      "nonce" => random_hex(16),
      "pinned" => true,
      "webhook_id" => random_snowflake(),
      "type" => 0,
      "activity" => %{"type" => 2, "party_id" => random_hex(16)},
      "application" => %{
        "id" => random_snowflake(),
        "cover_image" => random_hex(32),
        "description" => random_hex(32),
        "icon" => random_hex(16),
        "name" => random_hex(8)
      },
      "message_reference" => %{
        "message_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      },
      "flags" => 0b100,
      "stickers" => [
        %{
          "id" => random_snowflake(),
          "pack_id" => random_snowflake(),
          "name" => random_hex(8),
          "description" => random_hex(16),
          "tags" => "abc,def",
          "asset" => random_hex(8),
          "preview_asset" => random_hex(8),
          "format_type" => 1
        }
      ],
      "referenced_message" => nil
    }

    merge_opts(defaults, opts)
  end

  @spec voice_state(keyword) :: map
  def voice_state(opts \\ []) do
    defaults = %{
      "guild_id" => random_snowflake(),
      "channel_id" => random_snowflake(),
      "user_id" => random_snowflake(),
      "member" => member(),
      "session_id" => random_hex(16),
      "deaf" => false,
      "mute" => false,
      "self_deaf" => true,
      "self_mute" => true,
      "self_stream" => true,
      "self_video" => false,
      "suppress" => false
    }

    merge_opts(defaults, opts)
  end

  @spec member(keyword) :: map
  def member(opts \\ []) do
    defaults = %{
      "user" => user(),
      "nick" => random_hex(8),
      "roles" => [random_snowflake(), random_snowflake(), random_snowflake()],
      "joined_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "premium_since" => DateTime.to_iso8601(DateTime.utc_now()),
      "deaf" => true,
      "mute" => true,
      "pending" => false
    }

    merge_opts(defaults, opts)
  end

  @spec user(keyword) :: map
  def user(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "username" => random_hex(8),
      "discriminator" => random_discriminator(),
      "avatar" => random_hex(8),
      "bot" => true,
      "system" => false,
      "mfa_enabled" => false,
      "locale" => "en_US",
      "verified" => false,
      "email" => nil,
      "flags" => Bitwise.<<<(1, 16),
      "premium_type" => 0,
      "public_flags" => Bitwise.<<<(1, 16)
    }

    merge_opts(defaults, opts)
  end

  @spec partial_user(keyword) :: map
  def partial_user(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "username" => random_hex(8),
      "discriminator" => random_discriminator(),
      "avatar" => random_hex(8)
    }

    merge_opts(defaults, opts)
  end

  @spec emoji(keyword) :: map
  def emoji(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "name" => random_hex(8),
      "roles" => [random_snowflake(), random_snowflake()],
      "user" => partial_user(Keyword.get(opts, :user, [])),
      "require_colons" => true,
      "managed" => false,
      "animated" => false,
      "available" => true
    }

    merge_opts(defaults, opts)
  end

  @spec attachment(keyword) :: map
  def attachment(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "filename" => random_hex(32),
      "size" => :rand.uniform(32_000_000),
      "url" => random_hex(32),
      "proxy_url" => random_hex(32),
      "height" => :rand.uniform(1080),
      "width" => :rand.uniform(1920)
    }

    merge_opts(defaults, opts)
  end

  @spec role(keyword) :: map
  def role(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "name" => random_hex(8),
      "color" => :rand.uniform(256 * 256 * 256),
      "hoist" => true,
      "position" => :rand.uniform(21) - 1,
      "permissions" => "2048",
      "managed" => false,
      "mentionable" => true,
      "tags" => %{"integration_id" => random_snowflake()}
    }

    merge_opts(defaults, opts)
  end

  @spec embed(keyword) :: map
  def embed(opts \\ []) do
    defaults = %{
      "title" => random_hex(8),
      "type" => "rich",
      "description" => random_hex(16),
      "url" => random_hex(8),
      "timestamp" => DateTime.to_iso8601(DateTime.utc_now()),
      "color" => :rand.uniform(256 * 256 * 256),
      "footer" => %{"text" => random_hex(8)},
      "image" => %{"url" => random_hex(8)},
      "thumbnail" => %{"url" => random_hex(8)},
      "video" => %{"url" => random_hex(8)},
      "provider" => %{"name" => random_hex(8), "url" => random_hex(8)},
      "author" => %{"name" => random_hex(8), "url" => random_hex(8), "icon_url" => random_hex(8)},
      "fields" => [%{"name" => random_hex(8), "value" => random_hex(8), "inline" => true}]
    }

    merge_opts(defaults, opts)
  end

  @spec presence(keyword) :: map
  def presence(opts \\ []) do
    defaults = %{
      "user" => partial_user(),
      "guild_id" => random_snowflake(),
      "status" => "online",
      "activities" => [activity()],
      "client_status" => %{
        "desktop" => "idle",
        "mobile" => "dnd",
        "web" => "offline"
      }
    }

    merge_opts(defaults, opts)
  end

  @spec activity(keyword) :: map
  def activity(opts \\ []) do
    defaults = %{
      "name" => random_hex(8),
      "type" => 4,
      "url" => random_hex(16),
      "created_at" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
      "timestamps" => %{
        "start" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
        "end" => DateTime.to_unix(DateTime.utc_now(), :millisecond)
      },
      "application_id" => random_snowflake(),
      "details" => random_hex(8),
      "state" => random_hex(16),
      "emoji" => %{
        "name" => random_hex(8),
        "id" => random_snowflake(),
        "animated" => true
      },
      "party" => %{"id" => random_hex(8), "size" => [5, 10]},
      "assets" => %{
        "large_image" => random_hex(8),
        "large_text" => random_hex(8),
        "small_image" => random_hex(8),
        "small_text" => random_hex(8)
      },
      "secrets" => %{
        "join" => random_hex(32),
        "spectate" => random_hex(32),
        "match" => random_hex(32)
      },
      "instance" => true,
      "flags" => 0b100110
    }

    merge_opts(defaults, opts)
  end

  @spec application(keyword) :: map
  def application(opts \\ []) do
    team_id = random_snowflake()
    # The `team user` flag is enabled
    team_user = user(id: team_id, username: "team#{team_id}", flags: 1024, public_flags: 1024)

    defaults = %{
      "id" => team_id,
      "name" => random_hex(8),
      "icon" => random_hex(16),
      "description" => random_hex(32),
      "bot_public" => true,
      "bot_require_code_grant" => false,
      "owner" => team_user,
      "team" => team()
    }

    merge_opts(defaults, opts)
  end

  @spec team(keyword) :: map
  def team(opts \\ []) do
    owner_id = random_snowflake()

    defaults = %{
      "id" => random_snowflake(),
      "icon" => random_hex(8),
      "members" => [team_member(id: owner_id), team_member(), team_member()],
      "owner_user_id" => owner_id
    }

    merge_opts(defaults, opts)
  end

  @spec team_member(keyword) :: map
  def team_member(opts \\ []) do
    defaults = %{
      "membership_state" => 2,
      "permissions" => ["*"],
      "team_id" => random_snowflake(),
      "user" => partial_user(Keyword.get(opts, :user, []))
    }

    merge_opts(defaults, opts)
  end

  defp merge_opts(defaults, opts) do
    opts_map = Map.new(opts, fn {key, value} -> {Atom.to_string(key), value} end)

    Map.merge(defaults, opts_map)
  end
end
