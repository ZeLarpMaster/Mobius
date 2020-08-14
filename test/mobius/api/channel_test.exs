defmodule Mobius.Api.ChannelTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "get_channel/2 returns {:ok, parse_channel()} if status is 200", ctx do
    raw = Samples.Channel.raw_channel(:minimal)

    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Channel.get_channel(ctx.client, channel_id)

    assert map == Parsers.Channel.parse_channel(raw)
  end

  test "list_guild_channels/2", ctx do
    raw = [
      Samples.Channel.raw_channel(:minimal),
      Samples.Channel.raw_channel(:minimal)
    ]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/channels"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Channel.list_guild_channels(ctx.client, guild_id)

    assert list == Parsers.Channel.parse_channel(raw)
  end

  test "create_channel/3 returns {:ok, parse_channel()} if status is 200", ctx do
    raw = Samples.Channel.raw_channel(:minimal)

    params = [
      name: random_hex(8),
      type: 0,
      topic: random_hex(16),
      bitrate: 16000,
      user_limit: 5,
      slowmode_s: 60,
      position: 10,
      overwrites: [],
      parent_id: nil,
      nsfw?: false
    ]

    json_body =
      params
      |> Enum.map(fn
        {:slowmode_s, v} -> {"rate_limit_per_user", v}
        {:overwrites, v} -> {"permission_overwrites", v}
        {:nsfw?, v} -> {"nsfw", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/channels"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Channel.create_channel(ctx.client, guild_id, params)

    assert map == Parsers.Channel.parse_channel(raw)
  end

  test "create_dm/2", ctx do
    raw = Samples.Channel.raw_channel(:minimal)
    user_id = random_snowflake()

    json_body =
      %{"recipient_id" => user_id}
      |> Jason.encode!()

    url = Client.base_url() <> "/users/@me/channels"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Channel.create_dm(ctx.client, user_id)

    assert map == Parsers.Channel.parse_channel(raw)
  end

  describe "edit_channel/3" do
    test "raises ArgumentError if no parameter is given", ctx do
      assert_raise ArgumentError, fn ->
        Api.Channel.edit_channel(ctx.client, 123, [])
      end
    end

    test "returns {:ok, parse_channel()} if status is 200", ctx do
      raw = Samples.Channel.raw_channel(:minimal) |> Map.put("name", "cool-channel")
      body = %{"name" => "cool-channel"}
      json_body = Jason.encode!(body)
      params = Enum.map(Enum.to_list(body), fn {k, v} -> {String.to_atom(k), v} end)

      channel_id = random_snowflake()
      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

      {:ok, map} = Api.Channel.edit_channel(ctx.client, channel_id, params)

      assert map == Parsers.Channel.parse_channel(raw)
    end
  end

  test "edit_channel_positions/3 returns :ok if status is 204", ctx do
    pairs = [{random_snowflake(), 0}, {random_snowflake(), 1}]

    json_body =
      pairs
      |> Enum.map(fn {id, pos} -> %{"id" => id, "position" => pos} end)
      |> Jason.encode!()

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/channels"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> {204, [], nil} end)

    assert :ok == Api.Channel.edit_channel_positions(ctx.client, guild_id, pairs)
  end

  test "delete_channel/2 returns {:ok, parse_channel()} if status is 200", ctx do
    raw = Samples.Channel.raw_channel(:minimal)

    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}"
    mock(fn %{method: :delete, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Channel.delete_channel(ctx.client, channel_id)

    assert map == Parsers.Channel.parse_channel(raw)
  end

  test "edit_channel_permissions/4", ctx do
    params = [type: "member", allow: :rand.uniform(5000), deny: :rand.uniform(5000)]

    json_body =
      params
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
      |> Map.new()
      |> Jason.encode!()

    channel_id = random_snowflake()
    id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/permissions/#{id}"
    mock(fn %{method: :put, url: ^url, body: ^json_body} -> {204, [], nil} end)

    assert :ok == Api.Channel.edit_channel_permissions(ctx.client, channel_id, id, params)
  end

  test "delete_channel_permission/3", ctx do
    channel_id = random_snowflake()
    id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/permissions/#{id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Channel.delete_channel_permission(ctx.client, channel_id, id)
  end

  test "trigger_typing_indicator/2", ctx do
    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/typing"
    mock(fn %{method: :post, url: ^url, body: ""} -> {204, [], nil} end)

    assert :ok == Api.Channel.trigger_typing_indicator(ctx.client, channel_id)
  end
end
