defmodule Mobius.Parsers.Guild do
  @moduledoc false

  alias Mobius.Parsers.Utils
  alias Mobius.Parsers.Channel
  alias Mobius.Parsers.Role

  @spec parse_guild(Utils.input(), Utils.path()) :: Utils.result()
  def parse_guild(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "name"},
      {:required, :icon, "icon"},
      {:required, :splash, "splash"},
      {:required, :discovery_splash, "discovery_splash"},
      {:optional, :owner?, "owner"},
      {:required, :owner_id, {:via, "owner_id", Utils, :parse_snowflake}},
      {:optional, :permissions, "permissions"},
      {:required, :region, "region"},
      {:required, :afk_channel_id, {:via, "afk_channel_id", Utils, :parse_snowflake}},
      {:required, :afk_timeout_s, "afk_timeout"},
      {:required, :verification_level,
       {:via, "verification_level", __MODULE__, :parse_verification_level}},
      {:required, :default_message_notifications,
       {:via, "default_message_notifications", __MODULE__, :parse_message_notifications}},
      {:required, :explicit_content_filter,
       {:via, "explicit_content_filter", __MODULE__, :parse_content_filter}},
      {:required, :roles, {:via, "roles", Role, :parse_role}},
      {:required, :emojis, "emojis"},
      {:required, :features, {:raw, "features", __MODULE__, :parse_features}},
      {:required, :mfa_level, {:via, "mfa_level", __MODULE__, :parse_mfa_level}},
      {:required, :application_id, {:via, "application_id", Utils, :parse_snowflake}},
      {:optional, :widget_enabled?, "widget_enabled"},
      {:optional, :widget_channel_id, {:via, "widget_channel_id", Utils, :parse_snowflake}},
      {:required, :system_channel_id, {:via, "system_channel_id", Utils, :parse_snowflake}},
      {:required, :system_channel_flags,
       {:via, "system_channel_flags", __MODULE__, :parse_system_channel_flags}},
      {:required, :rules_channel_id, {:via, "rules_channel_id", Utils, :parse_snowflake}},
      # GUILD_CREATE only fields
      {:optional, :joined_at, {:via, "joined_at", Utils, :parse_iso8601}},
      {:optional, :large?, "large"},
      {:optional, :unavailable?, "unavailable"},
      {:optional, :member_count, "member_count"},
      {:optional, :voice_states, "voice_states"},
      {:optional, :members, "members"},
      {:optional, :channels, {:via, "channels", Channel, :parse_channel}},
      {:optional, :presences, "presences"},
      # End of GUILD_CREATE only fields
      {:optional, :max_presences, "max_presences"},
      {:optional, :max_members, "max_members"},
      {:required, :vanity_url_code, "vanity_url_code"},
      {:required, :description, "description"},
      {:required, :banner, "banner"},
      {:required, :premium_tier, "premium_tier"},
      {:optional, :premium_subscription_count, "premium_subscription_count"},
      {:required, :preferred_locale, "preferred_locale"},
      {:required, :public_updates_channel_id,
       {:via, "public_updates_channel_id", Utils, :parse_snowflake}},
      {:optional, :max_video_channel_users, "max_video_channel_users"},
      # GET /guild/:guild_id with `with_counts: true` fields
      {:optional, :approximate_member_count, "approximate_member_count"},
      {:optional, :approximate_presence_count, "approximate_presence_count"}
      # End of GET /guild/:guild_id with `with_counts: true` fields
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_partial_guild(Utils.input(), Utils.path()) :: Utils.result()
  def parse_partial_guild(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "name"},
      {:required, :icon, "icon"},
      {:required, :features, {:raw, "features", __MODULE__, :parse_features}},
      {:required, :owner?, "owner"},
      {:required, :permissions, "permissions"}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_verification_level(integer, Utils.path()) :: atom | integer
  def parse_verification_level(0, _path), do: :none
  def parse_verification_level(1, _path), do: :low
  def parse_verification_level(2, _path), do: :medium
  def parse_verification_level(3, _path), do: :high
  def parse_verification_level(4, _path), do: :very_high
  def parse_verification_level(value, _path), do: value

  @spec parse_message_notifications(integer, Utils.path()) :: atom | integer
  def parse_message_notifications(0, _path), do: :all_messages
  def parse_message_notifications(1, _path), do: :only_mentions
  def parse_message_notifications(value, _path), do: value

  @spec parse_content_filter(integer, Utils.path()) :: atom | integer
  def parse_content_filter(0, _path), do: :disabled
  def parse_content_filter(1, _path), do: :member_without_roles
  def parse_content_filter(2, _path), do: :all_members
  def parse_content_filter(value, _path), do: value

  @spec parse_features(list(String.t()), Utils.path()) :: MapSet.t(atom)
  def parse_features(features, _path) do
    MapSet.new(features, fn feature ->
      feature
      |> String.downcase()
      |> String.to_atom()
    end)
  end

  @spec parse_mfa_level(integer, Utils.path()) :: atom | integer
  def parse_mfa_level(0, _path), do: :none
  def parse_mfa_level(1, _path), do: :elevated
  def parse_mfa_level(value, _path), do: value

  @system_channel_flags [:suppress_join_notifications, :suppress_premium_subscriptions]
  @spec parse_system_channel_flags(integer, Utils.path()) :: MapSet.t(atom)
  def parse_system_channel_flags(value, _path),
    do: Utils.parse_flags(value, @system_channel_flags)
end
