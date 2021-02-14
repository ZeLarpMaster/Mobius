defmodule Mobius.Models.ChannelMention do
  @moduledoc """
  Struct for Discord's Channel Mentions

  Related documentation:
  https://discord.com/developers/docs/resources/channel#channel-mention-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Channel
  alias Mobius.Models.Snowflake

  defstruct [
    :id,
    :guild_id,
    :type,
    :name
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          guild_id: Snowflake.t(),
          type: Channel.type(),
          name: String.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :type, &Channel.parse_type/1)
    |> add_field(map, :name)
  end

  def parse(_), do: nil
end
