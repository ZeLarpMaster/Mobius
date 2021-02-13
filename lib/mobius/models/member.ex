defmodule Mobius.Models.Member do
  @moduledoc """
  Struct for Discord's Member

  Related documentation:
  https://discord.com/developers/docs/resources/guild#guild-member-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  defstruct [
    :user,
    :nick,
    :roles,
    :joined_at,
    :premium_since,
    :deaf,
    :mute,
    :pending
  ]

  @type t :: %__MODULE__{
          user: User.t(),
          nick: String.t(),
          roles: [Snowflake.t()],
          joined_at: DateTime.t(),
          premium_since: DateTime.t() | nil,
          deaf: boolean,
          mute: boolean,
          pending: boolean | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :user, &User.parse/1)
    |> add_field(map, :nick)
    |> add_field(map, :roles, &parse_roles/1)
    |> add_field(map, :joined_at, &Timestamp.parse/1)
    |> add_field(map, :premium_since, &Timestamp.parse/1)
    |> add_field(map, :deaf)
    |> add_field(map, :mute)
    |> add_field(map, :pending)
  end

  def parse(_), do: nil

  defp parse_roles(roles), do: parse_list(roles, &Snowflake.parse/1)
end
