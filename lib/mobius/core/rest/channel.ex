defmodule Mobius.Core.Rest.Channel do
  @moduledoc false

  alias Mobius.Core.Rest.Client

  @spec list_guild_channels(Client.client(), integer) :: {:ok, [map]} | Client.error()
  def list_guild_channels(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/channels", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(& &1)
  end
end
