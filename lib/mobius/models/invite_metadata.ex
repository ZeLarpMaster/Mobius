defmodule Mobius.Models.InviteMetadata do
  @moduledoc """
  Struct for Discord's Invite Metadata

  Related documentation:
  https://discord.com/developers/docs/resources/invite#invite-metadata-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Timestamp

  defstruct [
    :uses,
    :max_uses,
    :max_age,
    :temporary,
    :created_at
  ]

  @type t :: %__MODULE__{
          uses: non_neg_integer(),
          max_uses: non_neg_integer(),
          max_age: non_neg_integer(),
          temporary: boolean,
          created_at: DateTime.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :uses)
    |> add_field(map, :max_uses)
    |> add_field(map, :max_age)
    |> add_field(map, :temporary)
    |> add_field(map, :created_at, &Timestamp.parse/1)
  end

  def parse(_), do: nil
end
