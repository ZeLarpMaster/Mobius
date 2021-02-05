defmodule Mobius.Models.Embed do
  @moduledoc """
  Struct for Discord's Embed

  Related documentation:
  https://discord.com/developers/docs/resources/channel#embed-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Timestamp

  defstruct [
    :title,
    :type,
    :description,
    :url,
    :timestamp,
    :color,
    :footer,
    :image,
    :thumbnail,
    :video,
    :provider,
    :author,
    :fields
  ]

  @type type ::
          :image
          | :rich
          | :video
          | :gifv
          | :article
          | :link

  @type t :: %__MODULE__{
          title: String.t() | nil,
          type: type() | nil,
          description: String.t() | nil,
          url: String.t() | nil,
          timestamp: DateTime.t() | nil,
          color: non_neg_integer() | nil,
          footer: __MODULE__.Footer.t() | nil,
          image: __MODULE__.Media.t() | nil,
          thumbnail: __MODULE__.Media.t() | nil,
          video: __MODULE__.Media.t() | nil,
          provider: __MODULE__.Provider.t() | nil,
          author: __MODULE__.Author.t() | nil,
          fields: [__MODULE__.Field.t()] | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :title)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :description)
    |> add_field(map, :url)
    |> add_field(map, :timestamp, &Timestamp.parse/1)
    |> add_field(map, :color)
    |> add_field(map, :footer, &__MODULE__.Footer.parse/1)
    |> add_field(map, :image, &__MODULE__.Media.parse/1)
    |> add_field(map, :thumbnail, &__MODULE__.Media.parse/1)
    |> add_field(map, :video, &__MODULE__.Media.parse/1)
    |> add_field(map, :provider, &__MODULE__.Provider.parse/1)
    |> add_field(map, :author, &__MODULE__.Author.parse/1)
    |> add_field(map, :fields, &parse_fields/1)
  end

  def parse(_), do: nil

  defp parse_type("rich"), do: :rich
  defp parse_type("image"), do: :image
  defp parse_type("video"), do: :video
  defp parse_type("gifv"), do: :gifv
  defp parse_type("article"), do: :article
  defp parse_type("link"), do: :link
  defp parse_type(_), do: nil

  defp parse_fields(value), do: parse_list(value, &__MODULE__.Field.parse/1)
end
