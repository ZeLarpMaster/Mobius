defmodule Mobius.Models.Ban do
  @moduledoc """
  Struct for Discord's Ban

  Related documentation:
  https://discord.com/developers/docs/resources/guild#ban-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.User

  defstruct [
    :reason,
    :user
  ]

  @type t :: %__MODULE__{
          reason: String.t() | nil,
          user: User.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :reason)
    |> add_field(map, :user, &User.parse/1)
  end

  def parse(_), do: nil
end
