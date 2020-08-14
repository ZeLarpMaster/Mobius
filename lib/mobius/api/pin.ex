defmodule Mobius.Api.Pin do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec pin_message(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def pin_message(client, channel_id, message_id) do
    Tesla.put(client, "/channels/:channel_id/pins/:message_id", "",
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.check_empty_response()
  end

  @spec unpin_message(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def unpin_message(client, channel_id, message_id) do
    Tesla.delete(client, "/channels/:channel_id/pins/:message_id",
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.check_empty_response()
  end

  @spec list_pins(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_pins(client, channel_id) do
    Tesla.get(client, "/channels/:channel_id/pins", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(Parsers.Message, :parse_message)
  end
end
