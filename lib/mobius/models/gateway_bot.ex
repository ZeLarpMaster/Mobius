defmodule Mobius.Models.GatewayBot do
  @moduledoc """
  Struct for the response of a GET /gateway/bot request

  Related documentation: https://discord.com/developers/docs/topics/gateway#get-gateway-bot
  """

  import Mobius.Model

  alias Mobius.Models.SessionStartLimit

  @behaviour Mobius.Model

  defstruct [:url, :shards, :session_start_limit]

  @type t :: %__MODULE__{
          url: String.t(),
          shards: non_neg_integer(),
          session_start_limit: SessionStartLimit.t()
        }

  @doc """
  Parses the given term into a `t:t()` if possible; returns nil otherwise

  ## Examples

      iex> alias Mobius.Models.{GatewayBot, SessionStartLimit}
      iex> parse("not a map")
      nil
      iex> parse(%{})
      %GatewayBot{}
      iex> parse(%{"url" => "wss://something", "shards" => 1, "session_start_limit" => %{}})
      %GatewayBot{url: "wss://something", shards: 1, session_start_limit: %SessionStartLimit{}}
  """
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :url)
    |> add_field(map, :shards)
    |> add_field(map, :session_start_limit, &SessionStartLimit.parse/1)
  end

  def parse(_), do: nil
end
