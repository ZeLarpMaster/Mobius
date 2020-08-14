defmodule Mobius.Api.MemberTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "list_members/3", ctx do
    raw = [Samples.Member.raw_member(:minimal)]

    params =
      query = [
        limit: :rand.uniform(1000),
        after: random_snowflake()
      ]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members"
    mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

    {:ok, list} = Api.Member.list_members(ctx.client, guild_id, params)

    assert list == Parsers.Member.parse_member(raw)
  end

  test "get_member/3", ctx do
    raw = Samples.Member.raw_member(:full)

    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/#{user_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, response} = Api.Member.get_member(ctx.client, guild_id, user_id)

    assert response == Parsers.Member.parse_member(raw)
  end

  test "edit_member/4", ctx do
    params = [
      nickname: random_hex(8),
      roles: [random_snowflake()],
      mute?: true,
      deaf?: false,
      channel_id: random_snowflake()
    ]

    json_body =
      params
      |> Enum.map(fn
        {:nickname, v} -> {"nick", v}
        {:mute?, v} -> {"mute", v}
        {:deaf?, v} -> {"deaf", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/#{user_id}"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> {204, [], nil} end)

    assert :ok == Api.Member.edit_member(ctx.client, guild_id, user_id, params)
  end

  test "edit_my_nickname/3", ctx do
    nickname = random_hex(8)
    nickname2 = random_hex(8)

    body = %{
      "nick" => nickname
    }

    json_body = Jason.encode!(body)

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/@me/nick"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(%{"nick" => nickname2}) end)

    {:ok, response} = Api.Member.edit_my_nickname(ctx.client, guild_id, nickname)

    assert response == nickname2
  end

  test "kick_member/3", ctx do
    guild_id = random_snowflake()
    user_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/#{user_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Member.kick_member(ctx.client, guild_id, user_id)
  end
end
