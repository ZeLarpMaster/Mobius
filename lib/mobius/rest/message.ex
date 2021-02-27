defmodule Mobius.Rest.Message do
  @moduledoc false

  alias Mobius.Models.Message
  alias Mobius.Models.Snowflake
  alias Mobius.Rest.Client

  @doc """
  Does the API call for "Create Message"'s with `content-type: application/json`

  This doesn't allow sending files since allowing both in the same function would make it very
  complicated with little added value. Instead sending files is implemented in `send_file/4`.
  """
  @spec send_message(Client.client(), Snowflake.t(), keyword) :: Client.result(Message.t())
  def send_message(client, channel_id, params) do
    body =
      %{}
      |> add_param(params, :content)
      |> add_param(params, :nonce)
      |> add_param(params, :tts)
      |> add_param(params, :embed)
      |> add_param(params, :allowed_mentions)
      |> add_param(params, :message_reference)

    client
    |> Tesla.post("/channels/:channel_id/messages", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(&Message.parse/1)
  end

  defp add_param(map, params, field) do
    if Keyword.has_key?(params, field) do
      Map.put(map, field, Keyword.fetch!(params, field))
    else
      map
    end
  end
end
