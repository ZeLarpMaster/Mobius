defmodule Mobius.Models.Integration.Account do
  @moduledoc """
  Struct for Discord's Integration Account

  Related documentation:
  https://discord.com/developers/docs/resources/guild#integration-account-object
  """

  import Mobius.Model

  @behaviour Mobius.Model

  defstruct [
    :id,
    :name
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id)
    |> add_field(map, :name)
  end

  def parse(_), do: nil
end
