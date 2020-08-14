defmodule Mobius.Api.Role do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec give_role(Client.client(), Snowflake.t(), Snowflake.t(), Snowflake.t()) ::
          :ok | Client.error()
  def give_role(client, guild_id, user_id, role_id) do
    Tesla.put(client, "/guilds/:guild_id/members/:user_id/roles/:role_id", "",
      opts: [path_params: [guild_id: guild_id, user_id: user_id, role_id: role_id]]
    )
    |> Client.check_empty_response()
  end

  @spec take_role(Client.client(), Snowflake.t(), Snowflake.t(), Snowflake.t()) ::
          :ok | Client.error()
  def take_role(client, guild_id, user_id, role_id) do
    Tesla.delete(client, "/guilds/:guild_id/members/:user_id/roles/:role_id",
      opts: [path_params: [guild_id: guild_id, user_id: user_id, role_id: role_id]]
    )
    |> Client.check_empty_response()
  end

  @spec list_roles(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_roles(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/roles", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Role, :parse_role)
  end

  @spec create_role(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def create_role(client, guild_id, params) do
    body =
      [
        {"name", :name},
        {"permissions", :permissions},
        {"color", :color},
        {"hoist", :hoisted?},
        {"mentionable", :mentionable?}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.post(client, "/guilds/:guild_id/roles", body, opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Role, :parse_role)
  end

  @spec edit_role_positions(Client.client(), Snowflake.t(), [{Snowflake.t(), integer}]) ::
          {:ok, list} | Client.error()
  def edit_role_positions(client, guild_id, pairs) do
    body = Enum.map(pairs, fn {id, pos} -> %{"id" => id, "position" => pos} end)

    Tesla.patch(client, "/guilds/:guild_id/roles", body, opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Role, :parse_role)
  end

  @spec edit_role(Client.client(), Snowflake.t(), Snowflake.t(), keyword) ::
          {:ok, map} | Client.error()
  def edit_role(client, guild_id, role_id, params) do
    body =
      [
        {"name", :name},
        {"permissions", :permissions},
        {"color", :color},
        {"hoist", :hoisted?},
        {"mentionable", :mentionable?}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.patch(client, "/guilds/:guild_id/roles/:role_id", body,
      opts: [path_params: [guild_id: guild_id, role_id: role_id]]
    )
    |> Client.parse_response(Parsers.Role, :parse_role)
  end

  @spec delete_role(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def delete_role(client, guild_id, role_id) do
    Tesla.delete(client, "/guilds/:guild_id/roles/:role_id",
      opts: [path_params: [guild_id: guild_id, role_id: role_id]]
    )
    |> Client.check_empty_response()
  end
end
