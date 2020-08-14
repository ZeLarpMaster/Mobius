defmodule Mobius.Api.Ban do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec ban_member(Client.client(), Snowflake.t(), Snowflake.t(), keyword) :: :ok | Client.error()
  def ban_member(client, guild_id, user_id, params) do
    body =
      [
        {"delete_message_days", :delete_message_days},
        {"reason", :reason}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.put(client, "/guilds/:guild_id/bans/:user_id", body,
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.check_empty_response()
  end

  @spec unban_member(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def unban_member(client, guild_id, user_id) do
    Tesla.delete(client, "/guilds/:guild_id/bans/:user_id",
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.check_empty_response()
  end

  @spec get_ban(Client.client(), Snowflake.t(), Snowflake.t()) ::
          {:ok, map} | Client.error()
  def get_ban(client, guild_id, user_id) do
    Tesla.get(client, "/guilds/:guild_id/bans/:user_id",
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.parse_response(Parsers.Ban, :parse_ban)
  end

  @spec list_bans(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_bans(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/bans", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Ban, :parse_ban)
  end
end
