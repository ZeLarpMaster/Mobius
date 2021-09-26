defmodule Mobius.Models.Embed.Field do
  @moduledoc """
  Struct for Discord's Embed's Field

  Related documentation:
  https://discord.com/developers/docs/resources/channel#embed-object-embed-field-structure
  """

  import Mobius.Model

  @behaviour Mobius.Model

  defstruct [
    :name,
    :value,
    :inline
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          inline: boolean | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :name)
    |> add_field(map, :value)
    |> add_field(map, :inline)
  end

  def parse(_), do: nil
end
