defmodule Mobius.Models.Reaction do
  @moduledoc """
  Struct for Discord's Reaction

  Related documentation:
  https://discord.com/developers/docs/resources/channel#reaction-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Emoji

  defstruct [
    :count,
    :me,
    :emoji
  ]

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          me: boolean,
          emoji: Emoji.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :count)
    |> add_field(map, :me)
    |> add_field(map, :emoji, &Emoji.parse/1)
  end

  def parse(_), do: nil
end
