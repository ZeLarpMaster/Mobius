defmodule Mobius.Models.StageInstance do
  @moduledoc """
  Struct for Discord's StageInstance

  Related documentation:
  https://discord.com/developers/docs/resources/stage-instance
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :id,
    :guild_id,
    :channel_id,
    :topic
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          guild_id: Snowflake.t(),
          channel_id: Snowflake.t(),
          topic: String.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :topic)
  end

  def parse(_), do: nil
end
