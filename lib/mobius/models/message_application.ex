defmodule Mobius.Models.MessageApplication do
  @moduledoc """
  Struct for Discord's Message Application

  Related documentation:
  https://discord.com/developers/docs/resources/channel#message-object-message-application-structure
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake

  defstruct [
    :id,
    :cover_image,
    :description,
    :icon,
    :name
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          cover_image: String.t() | nil,
          description: String.t(),
          icon: String.t() | nil,
          name: String.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :cover_image)
    |> add_field(map, :description)
    |> add_field(map, :icon)
    |> add_field(map, :name)
  end

  def parse(_), do: nil
end
