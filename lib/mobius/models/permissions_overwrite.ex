defmodule Mobius.Models.PermissionsOverwrite do
  @moduledoc """
  Struct for Discord's Permission Overwrites

  Related documentation:
  https://discord.com/developers/docs/resources/channel#overwrite-object
  """

  import Mobius.Model

  alias Mobius.Models.Permissions
  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :id,
    :type,
    :allow,
    :deny
  ]

  @type type :: :role | :member

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          type: type(),
          allow: Permissions.t(),
          deny: Permissions.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :allow, &Permissions.parse/1)
    |> add_field(map, :deny, &Permissions.parse/1)
  end

  def parse(_), do: nil

  defp parse_type(0), do: :role
  defp parse_type(1), do: :member
  defp parse_type(_), do: nil
end
