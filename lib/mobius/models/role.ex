defmodule Mobius.Models.Role do
  @moduledoc """
  Struct for Discord's Role

  Related documentation:
  https://discord.com/developers/docs/topics/permissions#role-object
  """

  import Mobius.Model

  alias Mobius.Models.Permissions
  alias Mobius.Models.RoleTags
  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :id,
    :name,
    :color,
    :hoist,
    :position,
    :permissions,
    :managed,
    :mentionable,
    :tags
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          color: non_neg_integer(),
          hoist: boolean,
          position: non_neg_integer(),
          permissions: Permissions.t(),
          managed: boolean,
          mentionable: boolean,
          tags: RoleTags.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :color)
    |> add_field(map, :hoist)
    |> add_field(map, :position)
    |> add_field(map, :permissions, &Permissions.parse/1)
    |> add_field(map, :managed)
    |> add_field(map, :mentionable)
    |> add_field(map, :tags, &RoleTags.parse/1)
  end

  def parse(_), do: nil
end
