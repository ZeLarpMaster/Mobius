defmodule Mobius.Models.Status do
  @moduledoc "Represents the bot's status"

  defstruct since: nil, afk: false, status: "online", game: nil

  @spec serialize(Status.t()) :: map()
  def serialize(%__MODULE__{} = status) do
    %{
      "since" => status.since,
      "afk" => status.afk,
      "game" => status.game,
      "status" => status.status
    }
  end

  @spec deserialize(map) :: Status.t()
  def deserialize(map) do
    %__MODULE__{
      since: Map.get(map, "since", nil),
      afk: Map.get(map, "afk", false),
      game: Map.get(map, "game", nil),
      status: Map.get(map, "status", "online")
    }
  end
end
