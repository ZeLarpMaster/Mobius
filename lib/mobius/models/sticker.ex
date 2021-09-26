defmodule Mobius.Models.Sticker do
  @moduledoc """
  Struct for Discord's Sticker

  Related documentation:
  https://discord.com/developers/docs/resources/channel#message-object-message-sticker-structure
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :id,
    :pack_id,
    :name,
    :description,
    :tags,
    :asset,
    :preview_asset,
    :format_type
  ]

  @type type :: :png | :apng | :lottie

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          pack_id: Snowflake.t(),
          name: String.t(),
          description: String.t(),
          tags: [String.t()] | nil,
          asset: String.t(),
          preview_asset: String.t() | nil,
          format_type: type()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :pack_id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :description)
    |> add_field(map, :tags, &parse_tags/1)
    |> add_field(map, :asset)
    |> add_field(map, :preview_asset)
    |> add_field(map, :format_type, &parse_type/1)
  end

  def parse(_), do: nil

  defp parse_type(1), do: :png
  defp parse_type(2), do: :apng
  defp parse_type(3), do: :lottie
  defp parse_type(_), do: nil

  defp parse_tags(tags) when is_binary(tags), do: String.split(tags, ",")
  defp parse_tags(_), do: nil
end
