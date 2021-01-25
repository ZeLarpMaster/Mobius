defmodule Mobius.Models.Emoji do
  @moduledoc """
  Struct for Discord's Custom Emoji

  Related documentation:
  https://discord.com/developers/docs/resources/emoji#emoji-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

  defstruct [
    :id,
    :name,
    :roles,
    :user,
    :require_colons,
    :managed,
    :animated,
    :available
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t() | nil,
          name: String.t() | nil,
          roles: [Snowflake.t()] | nil,
          user: User.partial(),
          require_colons: boolean,
          managed: boolean,
          animated: boolean,
          available: boolean
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :roles, &parse_roles/1)
    |> add_field(map, :user, &User.parse/1)
    |> add_field(map, :require_colons)
    |> add_field(map, :managed)
    |> add_field(map, :animated)
    |> add_field(map, :available)
  end

  def parse(_), do: nil

  defp parse_roles(list), do: parse_list(list, &Snowflake.parse/1)
end
