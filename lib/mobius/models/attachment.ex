defmodule Mobius.Models.Attachment do
  @moduledoc """
  Struct for Discord's Attachment

  Related documentation:
  https://discord.com/developers/docs/resources/channel#attachment-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake

  defstruct [
    :id,
    :filename,
    :size,
    :url,
    :proxy_url,
    :height,
    :width
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          filename: String.t(),
          size: non_neg_integer(),
          url: String.t(),
          proxy_url: String.t(),
          height: non_neg_integer() | nil,
          width: non_neg_integer() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :filename)
    |> add_field(map, :size)
    |> add_field(map, :url)
    |> add_field(map, :proxy_url)
    |> add_field(map, :height)
    |> add_field(map, :width)
  end

  def parse(_), do: nil
end
