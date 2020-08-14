defmodule Mobius.Api.RoleTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "give_role/4", ctx do
    guild_id = random_snowflake()
    user_id = random_snowflake()
    role_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}"
    mock(fn %{method: :put, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Role.give_role(ctx.client, guild_id, user_id, role_id)
  end

  test "take_role/4", ctx do
    guild_id = random_snowflake()
    user_id = random_snowflake()
    role_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Role.take_role(ctx.client, guild_id, user_id, role_id)
  end

  test "list_roles/2", ctx do
    raw = [
      Samples.Role.raw_role(:full),
      Samples.Role.raw_role(:full)
    ]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/roles"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Role.list_roles(ctx.client, guild_id)

    assert list == Parsers.Role.parse_role(raw)
  end

  test "create_role/3", ctx do
    raw = Samples.Role.raw_role(:full)

    params = [
      name: raw["name"],
      permissions: raw["permissions"],
      color: raw["color"],
      hoisted?: true,
      mentionable?: true
    ]

    json_body =
      params
      |> Enum.map(fn
        {:hoisted?, v} -> {"hoist", v}
        {:mentionable?, v} -> {"mentionable", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/roles"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Role.create_role(ctx.client, guild_id, params)

    assert map == Parsers.Role.parse_role(raw)
  end

  test "edit_role_positions/3", ctx do
    raw = [Samples.Role.raw_role(:full), Samples.Role.raw_role(:full)]

    pairs = [{random_snowflake(), 1}, {random_snowflake(), 2}]

    json_body =
      pairs
      |> Enum.map(fn {id, pos} -> %{"id" => id, "position" => pos} end)
      |> Jason.encode!()

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/roles"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, list} = Api.Role.edit_role_positions(ctx.client, guild_id, pairs)

    assert list == Parsers.Role.parse_role(raw)
  end

  test "edit_role/4", ctx do
    raw = Samples.Role.raw_role(:full)

    params = [
      name: raw["name"],
      permissions: raw["permissions"],
      color: raw["color"],
      hoisted?: true,
      mentionable?: true
    ]

    json_body =
      params
      |> Enum.map(fn
        {:hoisted?, v} -> {"hoist", v}
        {:mentionable?, v} -> {"mentionable", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    role_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/roles/#{role_id}"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Role.edit_role(ctx.client, guild_id, role_id, params)

    assert map == Parsers.Role.parse_role(raw)
  end

  test "delete_role/3", ctx do
    guild_id = random_snowflake()
    role_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/roles/#{role_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Role.delete_role(ctx.client, guild_id, role_id)
  end
end
