defmodule Mobius.Api.BanTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "ban_member/4", ctx do
    params = [delete_message_days: :rand.uniform(7), reason: random_hex(16)]

    json_body =
      params
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/bans/#{user_id}"
    mock(fn %{method: :put, url: ^url, body: ^json_body} -> {204, [], nil} end)

    assert :ok == Api.Ban.ban_member(ctx.client, guild_id, user_id, params)
  end

  test "unban_member/3", ctx do
    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/bans/#{user_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Ban.unban_member(ctx.client, guild_id, user_id)
  end

  test "get_ban/3", ctx do
    raw = %{
      "reason" => random_hex(8),
      "user" => Samples.User.raw_user(:minimal)
    }

    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/bans/#{user_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Ban.get_ban(ctx.client, guild_id, user_id)

    assert map == Parsers.Ban.parse_ban(raw)
  end

  test "list_bans/2", ctx do
    raw = [
      %{"reason" => random_hex(8), "user" => Samples.User.raw_user(:minimal)}
    ]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/bans"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Ban.list_bans(ctx.client, guild_id)

    assert list == Parsers.Ban.parse_ban(raw)
  end
end
