defmodule Mobius.Api.Member do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec parse_nickname(map) :: String.t()
  def parse_nickname(response) do
    response["nick"]
  end

  @spec list_members(Client.client(), Snowflake.t(), keyword) :: {:ok, list} | Client.error()
  def list_members(client, guild_id, params) do
    query =
      [
        limit: Keyword.get(params, :limit),
        after: Keyword.get(params, :after)
      ]
      |> Enum.filter(fn {_, x} -> x != nil end)

    Tesla.get(client, "/guilds/:guild_id/members",
      query: query,
      opts: [path_params: [guild_id: guild_id]]
    )
    |> Client.parse_response(Parsers.Member, :parse_member)
  end

  @spec get_member(Client.client(), Snowflake.t(), Snowflake.t()) :: {:ok, map} | Client.error()
  def get_member(client, guild_id, user_id) do
    Tesla.get(client, "/guilds/:guild_id/members/:user_id",
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.parse_response(Parsers.Member, :parse_member)
  end

  @spec edit_member(Client.client(), Snowflake.t(), Snowflake.t(), keyword) ::
          :ok | Client.error()
  def edit_member(client, guild_id, user_id, params) do
    body =
      [
        {"nick", :nickname},
        {"roles", :roles},
        {"mute", :mute?},
        {"deaf", :deaf?},
        {"channel_id", :channel_id}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.patch(client, "/guilds/:guild_id/members/:user_id", body,
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.check_empty_response()
  end

  @spec edit_my_nickname(Client.client(), Snowflake.t(), String.t()) ::
          {:ok, String.t()} | Client.error()
  def edit_my_nickname(client, guild_id, nickname) do
    body = %{"nick" => nickname}

    Tesla.patch(client, "/guilds/:guild_id/members/@me/nick", body,
      opts: [path_params: [guild_id: guild_id]]
    )
    |> Client.parse_response(__MODULE__, :parse_nickname)
  end

  @spec kick_member(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def kick_member(client, guild_id, user_id) do
    Tesla.delete(client, "/guilds/:guild_id/members/:user_id",
      opts: [path_params: [guild_id: guild_id, user_id: user_id]]
    )
    |> Client.check_empty_response()
  end
end
