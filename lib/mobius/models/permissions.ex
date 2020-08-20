defmodule Mobius.Models.Permissions do
  @moduledoc "Functions to manipulate user permissions"

  import Bitwise

  @type permission :: integer

  # {name, permission_bit, channel_types, 2fa_required?}
  @permissions [
    {:create_instant_invite, 1 <<< 0, [:text, :voice], false},
    {:kick_members, 1 <<< 1, [], true},
    {:ban_members, 1 <<< 2, [], true},
    {:administrator, 1 <<< 3, [], true},
    {:manage_channels, 1 <<< 4, [:text, :voice], true},
    {:manage_guild, 1 <<< 5, [], true},
    {:add_reactions, 1 <<< 6, [:text], false},
    {:view_audit_log, 1 <<< 7, [], false},
    {:priority_speaker, 1 <<< 8, [:voice], false},
    {:stream, 1 <<< 9, [:voice], false},
    {:view_channel, 1 <<< 10, [:text, :voice], false},
    {:send_messages, 1 <<< 11, [:text], false},
    {:send_tts_messages, 1 <<< 12, [:text], false},
    {:manage_messages, 1 <<< 13, [:text], true},
    {:embed_links, 1 <<< 14, [:text], false},
    {:attach_files, 1 <<< 15, [:text], false},
    {:read_message_history, 1 <<< 16, [:text], false},
    {:mention_everyone, 1 <<< 17, [:text], false},
    {:use_external_emojis, 1 <<< 18, [:text], false},
    {:view_guild_insights, 1 <<< 19, [], false},
    {:connect, 1 <<< 20, [:voice], false},
    {:speak, 1 <<< 21, [:voice], false},
    {:mute_members, 1 <<< 22, [:voice], false},
    {:deafen_members, 1 <<< 23, [:voice], false},
    {:move_members, 1 <<< 24, [:voice], false},
    {:use_vad, 1 <<< 25, [:voice], false},
    {:change_nickname, 1 <<< 26, [], false},
    {:manage_nicknames, 1 <<< 27, [], false},
    {:manage_roles, 1 <<< 28, [:text, :voice], true},
    {:manage_webhooks, 1 <<< 29, [:text, :voice], true},
    {:manage_emojis, 1 <<< 30, [], true}
  ]

  @spec has_permission?(atom, permission()) :: boolean
  @spec mfa_required?(atom) :: boolean
  @spec permission_applies?(atom, :text | :voice) :: boolean

  for {name, bit, applicable_channel_types, mfa_required?} <- @permissions do
    def has_permission?(unquote(name), value), do: (value &&& unquote(bit)) == unquote(bit)
    def mfa_required?(unquote(name)), do: unquote(mfa_required?)

    for channel_type <- applicable_channel_types do
      def permission_applies?(unquote(name), unquote(channel_type)), do: true
    end

    def permission_applies?(unquote(name), _channel_type), do: false
  end

  @spec permission_from_names(MapSet.t(atom)) :: permission()
  def permission_from_names(names) do
    Mobius.Utils.create_bitflags(names, Enum.map(@permissions, &elem(&1, 0)))
  end
end
