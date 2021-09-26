defmodule Mobius.Models.MessageReference do
  @moduledoc """
  Struct for Discord's Message Reference

  Related documentation:
  https://discord.com/developers/docs/resources/channel#message-object-message-reference-structure
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :message_id,
    :channel_id,
    :guild_id
  ]

  @type t :: %__MODULE__{
          message_id: Snowflake.t() | nil,
          channel_id: Snowflake.t() | nil,
          guild_id: Snowflake.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :message_id, &Snowflake.parse/1)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
  end

  def parse(_), do: nil
end
