defmodule Mobius.Models.Embed.Footer do
  @moduledoc """
  Struct for Discord's Embed's Footer

  Related documentation:
  https://discord.com/developers/docs/resources/channel#embed-object-embed-footer-structure
  """

  import Mobius.Model

  @behaviour Mobius.Model

  defstruct [
    :text,
    :icon_url,
    :proxy_icon_url
  ]

  @type t :: %__MODULE__{
          text: String.t(),
          icon_url: String.t() | nil,
          proxy_icon_url: String.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :text)
    |> add_field(map, :icon_url)
    |> add_field(map, :proxy_icon_url)
  end

  def parse(_), do: nil
end
