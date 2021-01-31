defmodule Mobius.Models.MessageActivity do
  @moduledoc """
  Struct for Discord's Message Activity

  Related documentation:
  https://discord.com/developers/docs/resources/channel#message-object-message-activity-structure
  """

  import Mobius.Models.Utils

  defstruct [
    :type,
    :party_id
  ]

  @type type :: :join | :spectate | :listen | :join_request

  @type t :: %__MODULE__{
          type: type(),
          party_id: String.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :party_id)
  end

  def parse(_), do: nil

  defp parse_type(1), do: :join
  defp parse_type(2), do: :spectate
  defp parse_type(3), do: :listen
  defp parse_type(5), do: :join_request
  defp parse_type(_), do: nil
end
