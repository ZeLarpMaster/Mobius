defmodule Mobius.Models.GuildPreview do
  @moduledoc """
  Struct for Discord's Guild Preview

  You can find a list of `features` here:
  https://discord.com/developers/docs/resources/guild#guild-object-guild-features

  Related documentation:
  https://discord.com/developers/docs/resources/guild#guild-preview-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Emoji
  alias Mobius.Models.Snowflake

  defstruct [
    :id,
    :name,
    :icon,
    :splash,
    :discovery_splash,
    :emojis,
    :features,
    :approximate_member_count,
    :approximate_presence_count,
    :description
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          icon: String.t() | nil,
          splash: String.t() | nil,
          discovery_splash: String.t() | nil,
          emojis: [Emoji.t()],
          features: [String.t()],
          approximate_member_count: non_neg_integer(),
          approximate_presence_count: non_neg_integer(),
          description: String.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :icon)
    |> add_field(map, :splash)
    |> add_field(map, :discovery_splash)
    |> add_field(map, :emojis, &parse_emojis/1)
    |> add_field(map, :features)
    |> add_field(map, :approximate_member_count)
    |> add_field(map, :approximate_presence_count)
    |> add_field(map, :description)
  end

  def parse(_), do: nil

  defp parse_emojis(emojis), do: parse_list(emojis, &Emoji.parse/1)
end
