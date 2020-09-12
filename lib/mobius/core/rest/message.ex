defmodule Mobius.Core.Rest.Message do
  @moduledoc false

  alias Mobius.Core.Rest.Client

  @spec list_messages(Client.client(), integer, keyword) :: {:ok, [map]} | Client.error()
  def list_messages(client, channel_id, params) do
    position_params = Keyword.take(params, [:around, :before, :after])

    if length(position_params) > 1 do
      raise ArgumentError, message: ":around, :before, and :after are mutually exclusive"
    end

    Tesla.get(client, "/channels/:channel_id/messages",
      query: Keyword.take(params, [:limit]) ++ position_params,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(& &1)
  end
end
