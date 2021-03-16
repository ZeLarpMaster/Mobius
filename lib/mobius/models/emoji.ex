defmodule Mobius.Models.Emoji do
  @moduledoc """
  Struct for Discord's Custom Emoji

  All fields are `nil`-able and may or may not be provided depending on the source of the data.
  For example, a unicode emoji in a reaction will only have the `name` field or a custom emoji
  which was later deleted will only have the `id` field. See the Discord docs for more detail.

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
          user: User.partial() | nil,
          require_colons: boolean | nil,
          managed: boolean | nil,
          animated: boolean | nil,
          available: boolean | nil
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
