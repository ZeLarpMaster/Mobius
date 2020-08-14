defmodule Mobius.Api.UserTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "get_current_user/1", ctx do
    raw = Samples.User.raw_user(:minimal)

    url = Client.base_url() <> "/users/@me"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.User.get_current_user(ctx.client)

    assert map == Parsers.User.parse_user(raw)
  end

  test "edit_current_user/2", ctx do
    raw = Samples.User.raw_user(:minimal)

    params = [name: random_hex(8), avatar: random_hex(16)]

    json_body =
      params
      |> Enum.map(fn
        {:name, v} -> {"username", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    url = Client.base_url() <> "/users/@me"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.User.edit_current_user(ctx.client, params)

    assert map == Parsers.User.parse_user(raw)
  end

  test "get_user/2", ctx do
    raw = Samples.User.raw_user(:minimal)

    user_id = random_snowflake()
    url = Client.base_url() <> "/users/#{user_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.User.get_user(ctx.client, user_id)

    assert map == Parsers.User.parse_user(raw)
  end
end
