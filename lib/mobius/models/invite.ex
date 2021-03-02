defmodule Mobius.Models.Invite do
  @moduledoc """
  Struct for Discord's Invite

  Related documentation:
  https://discord.com/developers/docs/resources/invite#invite-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Channel
  alias Mobius.Models.User

  defstruct [
    :code,
    :guild,
    :channel,
    :inviter,
    :target_user,
    :target_user_type,
    :approximate_presence_count,
    :approximate_member_count
  ]

  @type target_type :: :stream

  @type t :: %__MODULE__{
          code: String.t(),
          # TODO: Guild.t()
          guild: map | nil,
          channel: Channel.partial(),
          inviter: User.t() | nil,
          target_user: User.partial() | nil,
          target_user_type: target_type() | nil,
          approximate_presence_count: non_neg_integer() | nil,
          approximate_member_count: non_neg_integer() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :code)
    |> add_field(map, :guild)
    |> add_field(map, :channel, &Channel.parse/1)
    |> add_field(map, :inviter, &User.parse/1)
    |> add_field(map, :target_user, &User.parse/1)
    |> add_field(map, :target_user_type, &parse_type/1)
    |> add_field(map, :approximate_presence_count)
    |> add_field(map, :approximate_member_count)
  end

  def parse(_), do: nil

  defp parse_type(1), do: :stream
  defp parse_type(_), do: nil
end
