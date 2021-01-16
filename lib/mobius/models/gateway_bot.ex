defmodule Mobius.Models.GatewayBot do
  @moduledoc """
  Struct for the response of a GET /gateway/bot request

  Related documentation: https://discord.com/developers/docs/topics/gateway#get-gateway-bot
  """

  import Mobius.Models.Utils

  alias Mobius.Models.SessionLimit

  defstruct [:url, :shards, :session_limit]

  @type t :: %__MODULE__{
          url: String.t(),
          shards: non_neg_integer(),
          session_limit: SessionLimit.t()
        }

  @doc """
  Parses the given term into a `t:t()` if possible; returns nil otherwise

  ## Examples

      iex> alias Mobius.Models.{GatewayBot, SessionLimit}
      iex> parse("not a map")
      nil
      iex> parse(%{})
      %GatewayBot{}
      iex> parse(%{"url" => "wss://something", "shards" => 1, "session_start_limit" => %{}})
      %GatewayBot{url: "wss://something", shards: 1, session_limit: %SessionLimit{}}
  """
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, "url", :url)
    |> add_field(map, "shards", :shards)
    |> add_field(map, "session_start_limit", :session_limit, &SessionLimit.parse/1)
  end

  def parse(_), do: nil
end
