defmodule Mobius.Api.GuildTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "create_guild/2 returns {:ok, parse_guild()} if status is 201", ctx do
    raw = Samples.Guild.raw_guild(:minimal)

    params = [
      name: random_hex(8),
      region: "us-east",
      icon: random_hex(64),
      verification_level: 1,
      default_message_notifications: 0,
      explicit_content_filter: 0,
      roles: [],
      channels: [],
      afk_channel_id: 1,
      afk_timeout: 1200,
      system_channel_id: 2
    ]

    json_body =
      params
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
      |> Map.new()
      |> Jason.encode!()

    url = Client.base_url() <> "/guilds"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw, 201) end)

    {:ok, map} = Api.Guild.create_guild(ctx.client, params)

    assert map == Parsers.Guild.parse_guild(raw)
  end

  test "get_guild/3 returns {:ok, parse_guild()} if status is 200", ctx do
    guild_id = random_snowflake()
    raw = Samples.Guild.raw_guild(:minimal)

    query = params = [with_counts: false]

    url = Client.base_url() <> "/guilds/#{guild_id}"
    mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

    {:ok, map} = Api.Guild.get_guild(ctx.client, guild_id, params)

    assert map == Parsers.Guild.parse_guild(raw)
  end

  test "edit_guild/3 returns {:ok, parse_guild()} if status is 200", ctx do
    raw = Samples.Guild.raw_guild(:minimal)
    guild_id = random_snowflake()

    params = [
      name: random_hex(8),
      region: "us-east",
      verification_level: 0,
      default_message_notifications: 1,
      explicit_content_filter: 1,
      afk_channel_id: random_snowflake(),
      afk_timeout_s: :rand.uniform(6000),
      icon: random_hex(16),
      owner_id: random_snowflake(),
      splash: random_hex(16),
      banner: random_hex(16),
      system_channel_id: random_snowflake(),
      rules_channel_id: random_snowflake(),
      public_updates_channel_id: random_snowflake(),
      preferred_locale: "en-US"
    ]

    json_body =
      params
      |> Enum.map(fn
        {:afk_timeout_s, v} -> {"afk_timeout", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    url = Client.base_url() <> "/guilds/#{guild_id}"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Guild.edit_guild(ctx.client, guild_id, params)

    assert map == Parsers.Guild.parse_guild(raw)
  end

  test "get_my_guilds/2 returns {:ok, parse_partial_guild()} if status is 200", ctx do
    raw = [Samples.Guild.raw_guild(:partial)]

    query = [
      before: 456,
      after: 100,
      limit: 10
    ]

    url = Client.base_url() <> "/users/@me/guilds"
    mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

    {:ok, list} = Api.Guild.get_my_guilds(ctx.client, query)

    assert list == Parsers.Guild.parse_partial_guild(raw)
  end

  test "leave_guild/2", ctx do
    guild_id = random_snowflake()
    url = Client.base_url() <> "/users/@me/guilds/#{guild_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Guild.leave_guild(ctx.client, guild_id)
  end

  test "delete_guild/2 returns :ok if status is 204", ctx do
    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Guild.delete_guild(ctx.client, guild_id)
  end
end
