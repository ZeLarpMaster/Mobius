defmodule Mobius.Models.Guild do
  @moduledoc """
  Struct for Discord's Guild

  Related documentation:
  https://discord.com/developers/docs/resources/guild#guild-object
  """

  import Mobius.Models.Utils

  alias Mobius.Core.Bitflags
  alias Mobius.Models.Channel
  alias Mobius.Models.Emoji
  alias Mobius.Models.Guild.WelcomeScreen
  alias Mobius.Models.Member
  alias Mobius.Models.Permissions
  alias Mobius.Models.Presence
  alias Mobius.Models.Role
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.Utils
  alias Mobius.Models.VoiceState

  defstruct [
    :id,
    :name,
    :icon,
    :icon_hash,
    :splash,
    :discovery_splash,
    :owner,
    :owner_id,
    :permissions,
    :region,
    :afk_channel_id,
    :afk_timeout,
    :widget_enabled,
    :widget_channel_id,
    :verification_level,
    :default_message_notifications,
    :explicit_content_filter,
    :roles,
    :emojis,
    :features,
    :mfa_level,
    :application_id,
    :system_channel_id,
    :system_channel_flags,
    :rules_channel_id,
    :joined_at,
    :large,
    :unavailable,
    :member_count,
    :voice_states,
    :members,
    :channels,
    :presences,
    :max_presences,
    :max_members,
    :vanity_url_code,
    :description,
    :banner,
    :premium_tier,
    :premium_subscription_count,
    :preferred_locale,
    :public_updates_channel_id,
    :max_video_channel_users,
    :approximate_member_count,
    :approximate_presence_count,
    :welcome_screen
  ]

  # Order is important, use nil for missing bitflags
  @system_channel_flags [
    :suppress_join_notifications,
    :suppress_premium_subscriptions
  ]

  @type feature ::
          :invite_splash
          | :vip_regions
          | :vanity_url
          | :verified
          | :partnered
          | :community
          | :commerce
          | :news
          | :discoverable
          | :featurable
          | :animated_icon
          | :banner
          | :welcome_screen_enabled
          | :member_verification_gate_enabled
          | :preview_enabled

  @type system_channel_flag ::
          :suppress_join_notifications
          | :suppress_premium_subscriptions

  @type verification_level :: :none | :low | :medium | :high | :very_high
  @type default_notification_level :: :all_messages | :only_mentions
  @type explicit_content_filter :: :disabled | :members_without_roles | :all_members
  @type features :: MapSet.t(feature())
  @type mfa_level :: :none | :elevated
  @type system_channel_flags :: MapSet.t(system_channel_flag())
  @type premium_tier :: :none | :tier_1 | :tier_2 | :tier_3

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          icon: String.t() | nil,
          icon_hash: String.t() | nil,
          splash: String.t() | nil,
          discovery_splash: String.t() | nil,
          owner: boolean | nil,
          owner_id: Snowflake.t(),
          permissions: Permissions.t() | nil,
          region: String.t(),
          afk_channel_id: Snowflake.t() | nil,
          afk_timeout: non_neg_integer(),
          widget_enabled: boolean | nil,
          widget_channel_id: Snowflake.t() | nil,
          verification_level: verification_level(),
          default_message_notifications: default_notification_level(),
          explicit_content_filter: explicit_content_filter(),
          roles: [Role.t()],
          emojis: [Emoji.t()],
          features: features(),
          mfa_level: mfa_level(),
          application_id: Snowflake.t() | nil,
          system_channel_id: Snowflake.t() | nil,
          system_channel_flags: system_channel_flags(),
          rules_channel_id: Snowflake.t() | nil,
          joined_at: DateTime.t() | nil,
          large: boolean | nil,
          unavailable: boolean | nil,
          member_count: non_neg_integer() | nil,
          voice_states: [VoiceState.t()] | nil,
          members: [Member.t()] | nil,
          channels: [Channel.t()] | nil,
          presences: [Presence.t()] | nil,
          max_presences: non_neg_integer() | nil,
          max_members: non_neg_integer() | nil,
          vanity_url_code: String.t() | nil,
          description: String.t() | nil,
          banner: String.t() | nil,
          premium_tier: premium_tier(),
          premium_subscription_count: non_neg_integer() | nil,
          preferred_locale: String.t(),
          public_updates_channel_id: Snowflake.t() | nil,
          max_video_channel_users: non_neg_integer() | nil,
          approximate_member_count: non_neg_integer() | nil,
          approximate_presence_count: non_neg_integer() | nil,
          welcome_screen: WelcomeScreen.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :icon)
    |> add_field(map, :icon_hash)
    |> add_field(map, :splash)
    |> add_field(map, :discovery_splash)
    |> add_field(map, :owner)
    |> add_field(map, :owner_id, &Snowflake.parse/1)
    |> add_field(map, :permissions, &Permissions.parse/1)
    |> add_field(map, :region)
    |> add_field(map, :afk_channel_id, &Snowflake.parse/1)
    |> add_field(map, :afk_timeout)
    |> add_field(map, :widget_enabled)
    |> add_field(map, :widget_channel_id, &Snowflake.parse/1)
    |> add_field(map, :verification_level, &parse_verification_level/1)
    |> add_field(map, :default_message_notifications, &parse_notification_level/1)
    |> add_field(map, :explicit_content_filter, &parse_content_filter/1)
    |> add_field(map, :roles, &parse_roles/1)
    |> add_field(map, :emojis, &parse_emojis/1)
    |> add_field(map, :features, &parse_features/1)
    |> add_field(map, :mfa_level, &parse_mfa_level/1)
    |> add_field(map, :application_id, &Snowflake.parse/1)
    |> add_field(map, :system_channel_id, &Snowflake.parse/1)
    |> add_field(map, :system_channel_flags, &Bitflags.parse_bitflags(&1, @system_channel_flags))
    |> add_field(map, :rules_channel_id, &Snowflake.parse/1)
    |> add_field(map, :joined_at, &Timestamp.parse/1)
    |> add_field(map, :large)
    |> add_field(map, :unavailable)
    |> add_field(map, :member_count)
    |> add_field(map, :voice_states, &parse_voice_states/1)
    |> add_field(map, :members, &parse_members/1)
    |> add_field(map, :channels, &parse_channels/1)
    |> add_field(map, :presences, &parse_presences/1)
    |> add_field(map, :max_presences)
    |> add_field(map, :max_members)
    |> add_field(map, :vanity_url_code)
    |> add_field(map, :description)
    |> add_field(map, :banner)
    |> add_field(map, :premium_tier, &parse_premium_tier/1)
    |> add_field(map, :premium_subscription_count)
    |> add_field(map, :preferred_locale)
    |> add_field(map, :public_updates_channel_id, &Snowflake.parse/1)
    |> add_field(map, :max_video_channel_users)
    |> add_field(map, :approximate_member_count)
    |> add_field(map, :approximate_presence_count)
    |> add_field(map, :welcome_screen, &WelcomeScreen.parse/1)
  end

  def parse(_), do: nil

  defp parse_verification_level(0), do: :none
  defp parse_verification_level(1), do: :low
  defp parse_verification_level(2), do: :medium
  defp parse_verification_level(3), do: :high
  defp parse_verification_level(4), do: :very_high
  defp parse_verification_level(_), do: nil

  defp parse_notification_level(0), do: :all_messages
  defp parse_notification_level(1), do: :only_mentions
  defp parse_notification_level(_), do: nil

  defp parse_content_filter(0), do: :disabled
  defp parse_content_filter(1), do: :members_without_roles
  defp parse_content_filter(2), do: :all_members
  defp parse_content_filter(_), do: nil

  defp parse_features(features) do
    MapSet.new(features, &String.to_atom(String.downcase(&1)))
  end

  defp parse_mfa_level(0), do: :none
  defp parse_mfa_level(1), do: :elevated
  defp parse_mfa_level(_), do: nil

  defp parse_premium_tier(0), do: :none
  defp parse_premium_tier(1), do: :tier_1
  defp parse_premium_tier(2), do: :tier_2
  defp parse_premium_tier(3), do: :tier_3
  defp parse_premium_tier(_), do: nil

  defp parse_roles(roles), do: Utils.parse_list(roles, &Role.parse/1)
  defp parse_emojis(emojis), do: Utils.parse_list(emojis, &Emoji.parse/1)
  defp parse_voice_states(states), do: Utils.parse_list(states, &VoiceState.parse/1)
  defp parse_members(members), do: Utils.parse_list(members, &Member.parse/1)
  defp parse_channels(channels), do: Utils.parse_list(channels, &Channel.parse/1)
  defp parse_presences(presences), do: Utils.parse_list(presences, &Presence.parse/1)
end
