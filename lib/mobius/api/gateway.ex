defmodule Mobius.Api.Gateway do
  @moduledoc false

  alias Mobius.Api.Client
  alias Mobius.Parsers

  @spec get_bot(Client.client()) :: {:ok, map} | Client.error()
  def get_bot(client) do
    Tesla.get(client, "/gateway/bot")
    |> Client.parse_response(Parsers.Gateway, :parse_gateway_bot)
  end

  @spec get_app_info(Client.client()) :: {:ok, map} | Client.error()
  def get_app_info(client) do
    Tesla.get(client, "/oauth2/applications/@me")
    |> Client.parse_response(Parsers.Gateway, :parse_app_info)
  end
end
