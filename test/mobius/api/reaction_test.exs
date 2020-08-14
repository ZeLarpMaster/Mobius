defmodule Mobius.Api.ReactionTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "create_reaction/4 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()

    for emoji <- ["👌", "Cake:733183336700182529"] do
      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode(emoji)}/@me"

      mock(fn %{method: :put, url: ^url} -> {204, [], nil} end)

      assert :ok == Api.Reaction.create_reaction(ctx.client, channel_id, message_id, emoji)
    end
  end

  test "delete_own_reaction/4 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()

    for emoji <- ["👌", "Cake:733183336700182529"] do
      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode(emoji)}/@me"

      mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

      assert :ok == Api.Reaction.delete_own_reaction(ctx.client, channel_id, message_id, emoji)
    end
  end

  test "delete_reaction/5 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()
    user_id = random_snowflake()

    for emoji <- ["👌", "Cake:733183336700182529"] do
      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}" <>
          "/reactions/#{URI.encode(emoji)}/#{user_id}"

      mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

      assert :ok ==
               Api.Reaction.delete_reaction(ctx.client, channel_id, message_id, emoji, user_id)
    end
  end

  test "list_reactions/5 returns {:ok, [parse_user()]} if status is 200", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()

    for emoji <- ["👌", "Cake:733183336700182529"] do
      raw = [Samples.User.raw_user(:minimal), Samples.User.raw_user(:minimal)]

      query = [before: 369, after: 321, limit: 5]

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode(emoji)}"

      mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

      {:ok, list} = Api.Reaction.list_reactions(ctx.client, channel_id, message_id, emoji, query)

      assert list == Parsers.User.parse_user(raw)
    end
  end

  test "delete_all_reactions/3 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/messages/#{message_id}/reactions"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Reaction.delete_all_reactions(ctx.client, channel_id, message_id)
  end

  test "delete_all_reactions_for_emoji/4 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()

    for emoji <- ["👌", "Cake:733183336700182529"] do
      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode(emoji)}"

      mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

      res = Api.Reaction.delete_all_reactions_for_emoji(ctx.client, channel_id, message_id, emoji)
      assert res == :ok
    end
  end
end
