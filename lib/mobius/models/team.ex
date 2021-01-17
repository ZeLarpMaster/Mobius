defmodule Mobius.Models.Team do
  @moduledoc """
  Struct for Discord's Team

  Related documentation:
  https://discord.com/developers/docs/topics/teams#data-models-team-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.TeamMember

  defstruct [
    :id,
    :icon,
    :members,
    :owner_user_id
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          icon: String.t() | nil,
          members: [TeamMember.t()],
          owner_user_id: Snowflake.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :icon)
    |> add_field(map, :members, &parse_members/1)
    |> add_field(map, :owner_user_id, &Snowflake.parse/1)
  end

  def parse(_), do: nil

  defp parse_members(list), do: parse_list(list, &TeamMember.parse/1)
end
