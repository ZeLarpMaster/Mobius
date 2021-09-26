defmodule Mobius.Models.Integration.Application do
  @moduledoc """
  Struct for Discord's Integration Application

  Related documentation:
  https://discord.com/developers/docs/resources/guild#integration-application-object
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

  @behaviour Mobius.Model

  defstruct [
    :id,
    :name,
    :icon,
    :description,
    :summary,
    :bot
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          icon: String.t() | nil,
          description: String.t(),
          summary: String.t(),
          bot: User.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :icon)
    |> add_field(map, :description)
    |> add_field(map, :summary)
    |> add_field(map, :bot, &User.parse/1)
  end

  def parse(_), do: nil
end
