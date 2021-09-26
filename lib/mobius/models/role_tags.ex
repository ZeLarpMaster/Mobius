defmodule Mobius.Models.RoleTags do
  @moduledoc """
  Struct for Discord's Role's tags

  Related documentation:
  https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake

  @behaviour Mobius.Model

  defstruct [
    :bot_id,
    :integration_id,
    :premium_subscriber
  ]

  @type t :: %__MODULE__{
          bot_id: Snowflake.t(),
          integration_id: Snowflake.t(),
          premium_subscriber: nil
        }

  @doc """
  Parses the given term into a `t:t()` if possible; returns nil otherwise

  ## Examples

      iex> alias Mobius.Models.RoleTags
      iex> parse("not a map")
      nil
      iex> parse(%{})
      %RoleTags{}
      iex> parse(%{"bot_id" => "123456", "integration_id" => nil, "premium_subscriber" => nil})
      %RoleTags{bot_id: 123456}
  """
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :bot_id, &Snowflake.parse/1)
    |> add_field(map, :integration_id, &Snowflake.parse/1)
    |> add_field(map, :premium_subscriber)
  end

  def parse(_), do: nil
end
