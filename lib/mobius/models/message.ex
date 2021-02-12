defmodule Mobius.Models.Message do
  @moduledoc """
  Struct for Discord's Message

  Related documentation:
  https://discord.com/developers/docs/resources/channel#message-object
  """

  import Mobius.Models.Utils

  alias Mobius.Core.Bitflags
  alias Mobius.Models.Attachment
  alias Mobius.Models.ChannelMention
  alias Mobius.Models.Embed
  alias Mobius.Models.Member
  alias Mobius.Models.MessageActivity
  alias Mobius.Models.MessageApplication
  alias Mobius.Models.MessageReference
  alias Mobius.Models.Reaction
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Sticker
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  defstruct [
    :id,
    :channel_id,
    :guild_id,
    :author,
    :member,
    :content,
    :timestamp,
    :edited_timestamp,
    :tts,
    :mention_everyone,
    :mentions,
    :mention_roles,
    :mention_channels,
    :attachments,
    :embeds,
    :reactions,
    :nonce,
    :pinned,
    :webhook_id,
    :type,
    :activity,
    :application,
    :message_reference,
    :flags,
    :stickers,
    :referenced_message
  ]

  @flags [
    :crossposted,
    :is_crosspost,
    :suppress_embeds,
    :source_message_deleted,
    :urgent
  ]

  @type flag ::
          :crossposted
          | :is_crosspost
          | :suppress_embeds
          | :source_message_deleted
          | :urgent
  @type flags :: MapSet.t(flag())

  @type type ::
          :default
          | :recipient_add
          | :recipient_remove
          | :call
          | :channel_name_change
          | :channel_icon_change
          | :channel_pinned_message
          | :guild_member_join
          | :user_premium_guild_subscription
          | :user_premium_guild_subscription_tier_1
          | :user_premium_guild_subscription_tier_2
          | :user_premium_guild_subscription_tier_3
          | :channel_follow_add
          | :guild_discovery_disqualified
          | :guild_discovery_requalified
          | :reply
          | :application_command

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          channel_id: Snowflake.t(),
          guild_id: Snowflake.t() | nil,
          author: User.t(),
          member: Member.t(),
          content: String.t(),
          timestamp: DateTime.t(),
          edited_timestamp: DateTime.t() | nil,
          tts: boolean,
          mention_everyone: boolean,
          mentions: [Member.t()] | nil,
          mention_roles: [Snowflake.t()],
          mention_channels: [ChannelMention.t()] | nil,
          attachments: [Attachment.t()],
          embeds: [Embed.t()],
          reactions: [Reaction.t()] | nil,
          nonce: String.t() | integer | nil,
          pinned: boolean,
          webhook_id: Snowflake.t() | nil,
          type: type(),
          activity: MessageActivity.t() | nil,
          application: MessageApplication.t() | nil,
          message_reference: MessageReference.t() | nil,
          flags: flags() | nil,
          stickers: [Sticker.t()] | nil,
          referenced_message: t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :author, &User.parse/1)
    |> add_field(map, :member, &inject_user_in_member(&1, map["user"]))
    |> add_field(map, :content)
    |> add_field(map, :timestamp, &Timestamp.parse/1)
    |> add_field(map, :edited_timestamp, &Timestamp.parse/1)
    |> add_field(map, :tts)
    |> add_field(map, :mention_everyone)
    |> add_field(map, :mentions, &parse_mentions/1)
    |> add_field(map, :mention_roles, &parse_role_ids/1)
    |> add_field(map, :mention_channels, &parse_channel_mentions/1)
    |> add_field(map, :attachments, &parse_attachments/1)
    |> add_field(map, :embeds, &parse_embeds/1)
    |> add_field(map, :reactions, &parse_reactions/1)
    |> add_field(map, :nonce)
    |> add_field(map, :pinned)
    |> add_field(map, :webhook_id, &Snowflake.parse/1)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :activity, &MessageActivity.parse/1)
    |> add_field(map, :application, &MessageApplication.parse/1)
    |> add_field(map, :message_reference, &MessageReference.parse/1)
    |> add_field(map, :flags, &parse_flags/1)
    |> add_field(map, :stickers, &parse_stickers/1)
    |> add_field(map, :referenced_message, &parse/1)
  end

  def parse(_), do: nil

  defp parse_type(0), do: :default
  defp parse_type(1), do: :recipient_add
  defp parse_type(2), do: :recipient_remove
  defp parse_type(3), do: :call
  defp parse_type(4), do: :channel_name_change
  defp parse_type(5), do: :channel_icon_change
  defp parse_type(6), do: :channel_pinned_message
  defp parse_type(7), do: :guild_member_join
  defp parse_type(8), do: :user_premium_guild_subscription
  defp parse_type(9), do: :user_premium_guild_subscription_tier_1
  defp parse_type(10), do: :user_premium_guild_subscription_tier_2
  defp parse_type(11), do: :user_premium_guild_subscription_tier_3
  defp parse_type(12), do: :channel_follow_add
  defp parse_type(14), do: :guild_discovery_disqualified
  defp parse_type(15), do: :guild_discovery_requalified
  defp parse_type(19), do: :reply
  defp parse_type(20), do: :application_command
  defp parse_type(_), do: nil

  defp parse_flags(flags) when is_integer(flags), do: Bitflags.parse_bitflags(flags, @flags)
  defp parse_flags(_flags), do: nil

  defp parse_stickers(stickers), do: parse_list(stickers, &Sticker.parse/1)
  defp parse_reactions(reactions), do: parse_list(reactions, &Reaction.parse/1)
  defp parse_embeds(embeds), do: parse_list(embeds, &Embed.parse/1)
  defp parse_attachments(attachments), do: parse_list(attachments, &Attachment.parse/1)
  defp parse_channel_mentions(mentions), do: parse_list(mentions, &ChannelMention.parse/1)
  defp parse_role_ids(role_ids), do: parse_list(role_ids, &Snowflake.parse/1)
  defp parse_mentions(mentions), do: parse_list(mentions, &parse_mention/1)
  defp parse_mention(user), do: inject_user_in_member(user["member"], user)
  defp inject_user_in_member(member, user), do: Member.parse(%{member | user: User.parse(user)})
end
