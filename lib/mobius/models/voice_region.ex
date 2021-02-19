defmodule Mobius.Models.VoiceRegion do
  @moduledoc """
  Struct for Discord's Voice Region

  Related documentation:
  https://discord.com/developers/docs/resources/voice#voice-region-object
  """

  import Mobius.Models.Utils

  defstruct [
    :id,
    :name,
    :vip,
    :optimal,
    :deprecated,
    :custom
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          vip: boolean,
          optimal: boolean,
          deprecated: boolean,
          custom: boolean
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id)
    |> add_field(map, :name)
    |> add_field(map, :vip)
    |> add_field(map, :optimal)
    |> add_field(map, :deprecated)
    |> add_field(map, :custom)
  end

  def parse(_), do: nil
end
