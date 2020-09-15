defmodule Mobius.Rest.Gateway do
  @moduledoc false

  alias Mobius.Rest.Client

  @spec get_bot(Client.client()) :: Client.result(map)
  def get_bot(client) do
    Tesla.get(client, "/gateway/bot")
    |> Client.parse_response(& &1)
  end

  @spec get_app_info(Client.client()) :: Client.result(map)
  def get_app_info(client) do
    Tesla.get(client, "/oauth2/applications/@me")
    |> Client.parse_response(& &1)
  end
end
