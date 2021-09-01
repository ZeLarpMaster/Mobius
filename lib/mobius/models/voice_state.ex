defmodule Mobius.Models.VoiceState do
  @moduledoc """
  Struct for Discord's Voice State

  Related documentation:
  https://discord.com/developers/docs/resources/voice#voice-state-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Member
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp

  defstruct [
    :guild_id,
    :channel_id,
    :user_id,
    :member,
    :session_id,
    :deaf,
    :mute,
    :self_deaf,
    :self_mute,
    :self_stream,
    :self_video,
    :suppress,
    :request_to_speak_timestamp
  ]

  @type t :: %__MODULE__{
          guild_id: Snowflake.t() | nil,
          channel_id: Snowflake.t() | nil,
          user_id: Snowflake.t(),
          member: Member.t() | nil,
          session_id: String.t(),
          deaf: boolean,
          mute: boolean,
          self_deaf: boolean,
          self_mute: boolean,
          self_stream: boolean | nil,
          self_video: boolean,
          suppress: boolean,
          request_to_speak_timestamp: DateTime.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :user_id, &Snowflake.parse/1)
    |> add_field(map, :member, &Member.parse/1)
    |> add_field(map, :session_id)
    |> add_field(map, :deaf)
    |> add_field(map, :mute)
    |> add_field(map, :self_deaf)
    |> add_field(map, :self_mute)
    |> add_field(map, :self_stream)
    |> add_field(map, :self_video)
    |> add_field(map, :suppress)
    |> add_field(map, :request_to_speak_timestamp, &Timestamp.parse/1)
  end

  def parse(_), do: nil
end
