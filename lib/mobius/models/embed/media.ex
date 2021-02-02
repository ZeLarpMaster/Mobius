defmodule Mobius.Models.Embed.Media do
  @moduledoc """
  Struct for Discord's Embed's Image, Thumbnail, and Video

  All three have the exact same fields with the exact same types

  Related documentation:
  https://discord.com/developers/docs/resources/channel#embed-object-embed-image-structure
  https://discord.com/developers/docs/resources/channel#embed-object-embed-thumbnail-structure
  https://discord.com/developers/docs/resources/channel#embed-object-embed-video-structure
  """

  import Mobius.Models.Utils

  defstruct [
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @type t :: %__MODULE__{
          url: String.t() | nil,
          proxy_url: String.t() | nil,
          height: non_neg_integer() | nil,
          width: non_neg_integer() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :url)
    |> add_field(map, :proxy_url)
    |> add_field(map, :height)
    |> add_field(map, :width)
  end

  def parse(_), do: nil
end
