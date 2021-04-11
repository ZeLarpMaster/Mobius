defmodule Mobius.Rest.Channel do
  @moduledoc false

  alias Mobius.Models.Channel
  alias Mobius.Models.Snowflake
  alias Mobius.Rest.Client

  @spec get_channel(Client.t(), Snowflake.t()) :: Client.result(Channel.t())
  def get_channel(client, channel_id) do
    client
    |> Tesla.get("/channels/:channel_id", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(&Channel.parse/1)
  end
end
