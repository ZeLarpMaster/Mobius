defmodule Mobius.Models.Guild.WelcomeScreen do
  @moduledoc """
  Struct for Discord's Guild Welcome Screen

  Related documentation:
  https://discord.com/developers/docs/resources/guild#welcome-screen-object
  """

  import Mobius.Model

  alias Mobius.Models.Guild.WelcomeChannel

  @behaviour Mobius.Model

  defstruct [
    :description,
    :welcome_channels
  ]

  @type t :: %__MODULE__{
          description: String.t() | nil,
          welcome_channels: [WelcomeChannel.t()]
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :description)
    |> add_field(map, :welcome_channels, &WelcomeChannel.parse/1)
  end

  def parse(_), do: nil
end
