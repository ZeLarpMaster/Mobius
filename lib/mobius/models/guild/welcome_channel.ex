defmodule Mobius.Models.Guild.WelcomeChannel do
  @moduledoc """
  Struct for Discord's Guild Welcome Channel

  Related documentation:
  https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake

  defstruct [
    :channel_id,
    :description,
    :emoji_id,
    :emoji_name
  ]

  @type t :: %__MODULE__{
          channel_id: Snowflake.t(),
          description: String.t(),
          emoji_id: Snowflake.t() | nil,
          emoji_name: String.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :description)
    |> add_field(map, :emoji_id, &Snowflake.parse/1)
    |> add_field(map, :emoji_name)
  end

  def parse(_), do: nil
end
