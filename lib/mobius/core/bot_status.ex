defmodule Mobius.Core.BotStatus do
  @moduledoc false

  defstruct type: :online,
            afk: false,
            game: nil,
            since: nil

  @type status_type :: :online | :idle | :dnd | :invisible
  @type game_type :: :playing | :streaming
  @type game :: %{type: game_type(), name: String.t(), url: String.t() | nil}

  @type t :: %__MODULE__{
          type: status_type(),
          afk: boolean,
          game: game() | nil,
          since: integer | nil
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec set_status(t(), status_type()) :: t()
  for status_type <- [:online, :idle, :dnd, :invisible] do
    def set_status(status, unquote(status_type)), do: struct!(status, type: unquote(status_type))
  end

  @spec set_playing(t(), String.t()) :: t()
  def set_playing(status, name), do: struct!(status, game: %{type: :playing, name: name})

  @spec set_streaming(t(), String.t(), String.t()) :: t()
  def set_streaming(status, name, url),
    do: struct!(status, game: %{type: :streaming, name: name, url: url})

  @spec set_afk(t(), integer() | nil) :: t()
  def set_afk(status, nil), do: struct!(status, afk: false, since: nil)
  def set_afk(status, since), do: struct!(status, afk: true, since: since)
end
