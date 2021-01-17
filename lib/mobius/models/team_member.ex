defmodule Mobius.Models.TeamMember do
  @moduledoc """
  Struct for Discord's Team Member

  Related documentation:
  https://discord.com/developers/docs/topics/teams#data-models-team-members-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

  defstruct [
    :membership_state,
    :permissions,
    :team_id,
    :user
  ]

  @type membership_state :: :invited | :accepted

  @type t :: %__MODULE__{
          membership_state: membership_state(),
          permissions: [String.t()],
          team_id: Snowflake.t(),
          user: User.partial()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :membership_state, &parse_membership/1)
    |> add_field(map, :permissions)
    |> add_field(map, :team_id, &Snowflake.parse/1)
    |> add_field(map, :user, &User.parse/1)
  end

  def parse(_), do: nil

  defp parse_membership(1), do: :invited
  defp parse_membership(2), do: :accepted
  defp parse_membership(_), do: nil
end
