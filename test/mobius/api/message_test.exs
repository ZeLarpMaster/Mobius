defmodule Mobius.Api.MessageTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  describe "list_messages/3" do
    test "raises ArgumentError if more than one of :around, :before, and :after is given", ctx do
      assert_raise ArgumentError, fn ->
        Api.Message.list_messages(ctx.client, 123, around: 123, before: 123)
      end

      assert_raise ArgumentError, fn ->
        Api.Message.list_messages(ctx.client, 123, around: 123, after: 123)
      end

      assert_raise ArgumentError, fn ->
        Api.Message.list_messages(ctx.client, 123, before: 123, after: 123)
      end

      assert_raise ArgumentError, fn ->
        Api.Message.list_messages(ctx.client, 123, around: 123, before: 123, after: 123)
      end
    end

    test "returns {:ok, [parse_message()]} if status is 200", ctx do
      raw = [
        Samples.Message.raw_message(:full),
        Samples.Message.raw_message(:full),
        Samples.Message.raw_message(:full)
      ]

      channel_id = random_snowflake()
      query = [limit: 25, around: 123]
      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

      {:ok, list} = Api.Message.list_messages(ctx.client, channel_id, query)

      assert list == Parsers.Message.parse_message(raw)
    end

    test "reverses the list if oldest_first: true", ctx do
      raw = [
        Samples.Message.raw_message(:full),
        Samples.Message.raw_message(:full),
        Samples.Message.raw_message(:full)
      ]

      channel_id = random_snowflake()
      query = [limit: 25, around: 123]
      params = query ++ [oldest_first: true]
      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :get, url: ^url, query: ^query} -> json(raw) end)

      {:ok, list} = Api.Message.list_messages(ctx.client, channel_id, params)

      assert list == Enum.reverse(Parsers.Message.parse_message(raw))
    end
  end

  test "get_message/3 returns {:ok, parse_message()} if status is 200", ctx do
    raw = Samples.Message.raw_message(:full)

    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/messages/#{message_id}"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Message.get_message(ctx.client, channel_id, message_id)

    assert map == Parsers.Message.parse_message(raw)
  end

  describe "create_message/3" do
    test "raises ArgumentError if neither content and embed is given", ctx do
      assert_raise ArgumentError, fn ->
        Api.Message.create_message(ctx.client, 123, [])
      end
    end

    test "returns {:ok, parse_message()} if status is 200", ctx do
      raw = Samples.Message.raw_message(:full)

      body = %{
        "content" => "Some content",
        "nonce" => "abcdef",
        "tts" => true,
        "embed" => %{},
        "payload_json" => "payload",
        "allowed_mentions" => %{"parse" => []}
      }

      json_body = Jason.encode!(body)

      params =
        body
        |> Enum.to_list()
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      channel_id = random_snowflake()
      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

      {:ok, map} = Api.Message.create_message(ctx.client, channel_id, params)

      assert map == Parsers.Message.parse_message(raw)
    end
  end

  test "edit_message/4 returns {:ok, parse_message()} if status is 200", ctx do
    raw = Samples.Message.raw_message(:full)

    body = %{
      "content" => "Some content",
      "embed" => %{"title" => "A title"},
      "flags" => 4
    }

    json_body = Jason.encode!(body)

    params =
      body
      |> Enum.to_list()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/messages/#{message_id}"
    mock(fn %{method: :patch, url: ^url, body: ^json_body} -> json(raw) end)

    {:ok, map} =
      Api.Message.edit_message(ctx.client, channel_id, message_id, params ++ [useless: "thing"])

    assert map == Parsers.Message.parse_message(raw)
  end

  test "delete_message/3 returns :ok if status is 204", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/messages/#{message_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Message.delete_message(ctx.client, channel_id, message_id)
  end

  describe "bulk_delete_messages/3" do
    test "raises FunctionClauseError when less than 2 or more than 100 messages are given", ctx do
      assert_raise FunctionClauseError, fn ->
        Api.Message.bulk_delete_messages(ctx.client, 123, [])
      end

      assert_raise FunctionClauseError, fn ->
        Api.Message.bulk_delete_messages(ctx.client, 123, [456])
      end

      assert_raise FunctionClauseError, fn ->
        Api.Message.bulk_delete_messages(ctx.client, 123, List.duplicate(456, 101))
      end
    end

    test "returns :ok if status is 204", ctx do
      message_ids = [random_snowflake(), random_snowflake(), random_snowflake()]

      body = Jason.encode!(%{"messages" => message_ids})

      channel_id = random_snowflake()
      url = Client.base_url() <> "/channels/#{channel_id}/messages/bulk-delete"
      mock(fn %{method: :post, url: ^url, body: ^body} -> {204, [], nil} end)

      assert :ok == Api.Message.bulk_delete_messages(ctx.client, channel_id, message_ids)
    end
  end
end
