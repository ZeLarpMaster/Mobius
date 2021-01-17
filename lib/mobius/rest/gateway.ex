defmodule Mobius.Rest.Gateway do
  @moduledoc false

  alias Mobius.Models
  alias Mobius.Rest.Client

  @spec get_bot(Client.client()) :: Client.result(Models.GatewayBot.t())
  def get_bot(client) do
    client
    |> Tesla.get("/gateway/bot")
    |> Client.parse_response(&Models.GatewayBot.parse/1)
  end

  @spec get_app_info(Client.client()) :: Client.result(map)
  def get_app_info(client) do
    client
    |> Tesla.get("/oauth2/applications/@me")
    |> Client.parse_response(& &1)
  end
end
