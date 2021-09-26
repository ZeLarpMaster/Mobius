defmodule Mobius.Models.Embed.Provider do
  @moduledoc """
  Struct for Discord's Embed's Provider

  Related documentation:
  https://discord.com/developers/docs/resources/channel#embed-object-embed-provider-structure
  """

  import Mobius.Model

  @behaviour Mobius.Model

  defstruct [
    :name,
    :url
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          url: String.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :name)
    |> add_field(map, :url)
  end

  def parse(_), do: nil
end
