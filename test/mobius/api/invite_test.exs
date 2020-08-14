defmodule Mobius.Api.InviteTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "list_guild_invites/2", ctx do
    raw = [Samples.Invite.raw_invite(:full)]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/invites"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Invite.list_guild_invites(ctx.client, guild_id)

    assert list == Parsers.Invite.parse_invite(raw)
  end

  test "list_channel_invites/2", ctx do
    raw = [Samples.Invite.raw_invite(:full)]

    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/invites"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Invite.list_channel_invites(ctx.client, channel_id)

    assert list == Parsers.Invite.parse_invite(raw)
  end

  test "get_invite/3", ctx do
    raw = Samples.Invite.raw_invite(:full)

    params = [
      with_counts?: true
    ]

    query = [
      with_counts: true
    ]

    invite_code = random_hex(8)
    url = Client.base_url() <> "/invites/#{invite_code}"
    mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

    {:ok, map} = Api.Invite.get_invite(ctx.client, invite_code, params)

    assert map == Parsers.Invite.parse_invite(raw)
  end

  test "create_invite/3", ctx do
    raw = Samples.Invite.raw_invite(:full)

    params = [
      max_age: :rand.uniform(100_000),
      max_uses: :rand.uniform(50),
      temporary?: true,
      unique?: true,
      target_user_id: random_snowflake(),
      target_user_type: 1
    ]

    json_body =
      params
      |> Enum.map(fn
        {:temporary?, v} -> {"temporary", v}
        {:unique?, v} -> {"unique", v}
        {:target_user_id, v} -> {"target_user", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/invites"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Invite.create_invite(ctx.client, channel_id, params)

    assert map == Parsers.Invite.parse_invite(raw)
  end

  test "delete_invite/2", ctx do
    raw = Samples.Invite.raw_invite(:full)

    invite_code = random_hex(8)
    url = Client.base_url() <> "/invites/#{invite_code}"
    mock(fn %{method: :delete, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Invite.delete_invite(ctx.client, invite_code)

    assert map == Parsers.Invite.parse_invite(raw)
  end
end
