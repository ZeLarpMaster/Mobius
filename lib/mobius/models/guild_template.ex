defmodule Mobius.Models.GuildTemplate do
  @moduledoc """
  Struct for Discord's Template

  Related documentation:
  https://discord.com/developers/docs/resources/template#template-object
  """

  import Mobius.Model

  alias Mobius.Models.Guild
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  @behaviour Mobius.Model

  defstruct [
    :code,
    :name,
    :description,
    :usage_count,
    :creator_id,
    :creator,
    :created_at,
    :updated_at,
    :source_guild_id,
    :serialized_source_guild,
    :is_dirty
  ]

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          description: String.t() | nil,
          usage_count: non_neg_integer(),
          creator_id: Snowflake.t(),
          creator: User.t(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          source_guild_id: Snowflake.t(),
          serialized_source_guild: Guild.t(),
          is_dirty: boolean | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :code)
    |> add_field(map, :name)
    |> add_field(map, :description)
    |> add_field(map, :usage_count)
    |> add_field(map, :creator_id, &Snowflake.parse/1)
    |> add_field(map, :creator, &User.parse/1)
    |> add_field(map, :created_at, &Timestamp.parse/1)
    |> add_field(map, :updated_at, &Timestamp.parse/1)
    |> add_field(map, :source_guild_id, &Snowflake.parse/1)
    |> add_field(map, :serialized_source_guild, &Guild.parse/1)
    |> add_field(map, :is_dirty)
  end

  def parse(_), do: nil
end
