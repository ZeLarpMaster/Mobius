defmodule Mobius.Models.GuildWidget do
  @moduledoc """
  Struct for Discord's GuildWidget

  Related documentation:
  https://discord.com/developers/docs/resources/guild#guild-widget-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake

  defstruct [
    :enabled,
    :channel_id
  ]

  @type t :: %__MODULE__{
          enabled: boolean,
          channel_id: Snowflake.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :enabled)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
  end

  def parse(_), do: nil
end
