defmodule Mobius.Api.Guild do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec create_guild(Client.client(), keyword) :: {:ok, map} | Client.error()
  def create_guild(client, params) do
    name = Keyword.fetch!(params, :name)

    body =
      [
        {"region", Keyword.get(params, :region, :unknown)},
        {"icon", Keyword.get(params, :icon, :unknown)},
        {"verification_level", Keyword.get(params, :verification_level, :unknown)},
        {"default_message_notifications",
         Keyword.get(params, :default_message_notifications, :unknown)},
        {"explicit_content_filter", Keyword.get(params, :explicit_content_filter, :unknown)},
        {"roles", Keyword.get(params, :roles, :unknown)},
        {"channels", Keyword.get(params, :channels, :unknown)},
        {"afk_channel_id", Keyword.get(params, :afk_channel_id, :unknown)},
        {"afk_timeout", Keyword.get(params, :afk_timeout, :unknown)},
        {"system_channel_id", Keyword.get(params, :system_channel_id, :unknown)}
      ]
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()
      |> Map.put("name", name)

    Tesla.post(client, "/guilds", body)
    |> Client.parse_response(Parsers.Guild, :parse_guild)
  end

  @spec get_guild(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def get_guild(client, guild_id, params) do
    query = Keyword.take(params, [:with_counts])

    Tesla.get(client, "/guilds/:guild_id",
      query: query,
      opts: [path_params: [guild_id: guild_id]]
    )
    |> Client.parse_response(Parsers.Guild, :parse_guild)
  end

  @spec edit_guild(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def edit_guild(client, guild_id, params) do
    body =
      [
        {"name", :name},
        {"region", :region},
        {"verification_level", :verification_level},
        {"default_message_notifications", :default_message_notifications},
        {"explicit_content_filter", :explicit_content_filter},
        {"afk_channel_id", :afk_channel_id},
        {"afk_timeout", :afk_timeout_s},
        {"icon", :icon},
        {"owner_id", :owner_id},
        {"splash", :splash},
        {"banner", :banner},
        {"system_channel_id", :system_channel_id},
        {"rules_channel_id", :rules_channel_id},
        {"public_updates_channel_id", :public_updates_channel_id},
        {"preferred_locale", :preferred_locale}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.patch(client, "/guilds/:guild_id", body, opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Guild, :parse_guild)
  end

  @spec get_my_guilds(Client.client(), keyword) :: {:ok, list(map)} | Client.error()
  def get_my_guilds(client, params) do
    Tesla.get(client, "/users/@me/guilds", query: Keyword.take(params, [:before, :after, :limit]))
    |> Client.parse_response(Parsers.Guild, :parse_partial_guild)
  end

  @spec leave_guild(Client.client(), Snowflake.t()) :: :ok | Client.error()
  def leave_guild(client, guild_id) do
    Tesla.delete(client, "/users/@me/guilds/:guild_id", opts: [path_params: [guild_id: guild_id]])
    |> Client.check_empty_response()
  end

  @spec delete_guild(Client.client(), Snowflake.t()) :: :ok | Client.error()
  def delete_guild(client, guild_id) do
    Tesla.delete(client, "/guilds/:guild_id", opts: [path_params: [guild_id: guild_id]])
    |> Client.check_empty_response()
  end
end
