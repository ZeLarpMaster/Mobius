defmodule Mobius.Api.EmojiTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "list_emojis/2", ctx do
    raw = [Samples.Emoji.raw_emoji(:full)]

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/emojis"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Emoji.list_emojis(ctx.client, guild_id)

    assert list == Parsers.Emoji.parse_emoji(raw)
  end

  test "get_emoji/3", ctx do
    raw = Samples.Emoji.raw_emoji(:full)

    guild_id = random_snowflake()
    emoji_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/emojis/#{emoji_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Emoji.get_emoji(ctx.client, guild_id, emoji_id)

    assert map == Parsers.Emoji.parse_emoji(raw)
  end

  test "create_emoji/3", ctx do
    raw = Samples.Emoji.raw_emoji(:full)

    params = [
      name: random_hex(8),
      image: random_hex(64),
      role_ids: [random_snowflake()]
    ]

    json_body =
      params
      |> Enum.map(fn
        {:role_ids, v} -> {"roles", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/emojis"
    mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Emoji.create_emoji(ctx.client, guild_id, params)

    assert map == Parsers.Emoji.parse_emoji(raw)
  end

  test "edit_emoji/4", ctx do
    raw = Samples.Emoji.raw_emoji(:full)

    params = [
      name: random_hex(8),
      role_ids: [random_snowflake()]
    ]

    json_body =
      params
      |> Enum.map(fn
        {:role_ids, v} -> {"roles", v}
        {k, v} -> {Atom.to_string(k), v}
      end)
      |> Map.new()
      |> Jason.encode!()

    guild_id = random_snowflake()
    emoji_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/emojis/#{emoji_id}"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} = Api.Emoji.edit_emoji(ctx.client, guild_id, emoji_id, params)

    assert map == Parsers.Emoji.parse_emoji(raw)
  end

  test "delete_emoji/3", ctx do
    guild_id = random_snowflake()
    emoji_id = random_snowflake()
    url = Client.base_url() <> "/guilds/#{guild_id}/emojis/#{emoji_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], ""} end)

    assert :ok == Api.Emoji.delete_emoji(ctx.client, guild_id, emoji_id)
  end
end
