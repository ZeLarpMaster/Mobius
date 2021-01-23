defmodule Mobius.Models.Permissions do
  @moduledoc """
  Model for Discord's permissions and utility functions to manipulate them

  Related documentation:
  https://discord.com/developers/docs/topics/permissions
  """

  alias Mobius.Core.Bitflags
  alias Mobius.Models.Utils

  # Order is important, use nil for missing bitflags
  @permissions [
    :create_instant_invite,
    :kick_members,
    :ban_members,
    :administrator,
    :manage_channels,
    :manage_guild,
    :add_reactions,
    :view_audit_log,
    :priority_speaker,
    :stream,
    :view_channel,
    :send_messages,
    :send_tts_messages,
    :manage_messages,
    :embed_links,
    :attach_files,
    :read_message_history,
    :mention_everyone,
    :use_external_emojis,
    :view_guild_insights,
    :connect,
    :speak,
    :mute_members,
    :deafen_members,
    :move_members,
    :use_vad,
    :change_nickname,
    :manage_nicknames,
    :manage_roles,
    :manage_webhooks,
    :manage_emojis
  ]

  @type permission ::
          :create_instant_invite
          | :kick_members
          | :ban_members
          | :administrator
          | :manage_channels
          | :manage_guild
          | :add_reactions
          | :view_audit_log
          | :priority_speaker
          | :stream
          | :view_channel
          | :send_messages
          | :send_tts_messages
          | :manage_messages
          | :embed_links
          | :attach_files
          | :read_message_history
          | :mention_everyone
          | :use_external_emojis
          | :view_guild_insights
          | :connect
          | :speak
          | :mute_members
          | :deafen_members
          | :move_members
          | :use_vad
          | :change_nickname
          | :manage_nicknames
          | :manage_roles
          | :manage_webhooks
          | :manage_emojis

  @type t :: MapSet.t(permission())

  @doc "Returns all permissions possible"
  @spec all_permissions() :: MapSet.t(permission())
  def all_permissions, do: MapSet.new(@permissions)

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: MapSet.t(permission()) | nil
  def parse(string) when is_binary(string) do
    case Utils.parse_integer(string) do
      nil -> nil
      integer -> Bitflags.parse_bitflags(integer, @permissions)
    end
  end

  def parse(_), do: nil
end
