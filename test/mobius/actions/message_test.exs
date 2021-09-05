defmodule Mobius.Actions.MessageTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Message
  alias Mobius.Models
  alias Mobius.Rest.Client

  setup :reset_services
  setup :create_rest_client
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard

  test "send_message/2 when the bot isn't ready" do
    {:error, error} = Message.send_message(%{content: random_hex(8)}, random_snowflake())
    assert error =~ "must be ready"
  end

  describe "send_message/2 when the bot is ready" do
    setup :handshake_shard

    setup do
      channel_id = random_snowflake()
      raw = message(channel_id: channel_id)
      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :post, url: ^url} -> json(raw) end)
      [channel_id: channel_id, raw_message: raw]
    end

    test "returns an error if none of content, embed or file is given", ctx do
      {:error, error} = Message.send_message(%{}, ctx.channel_id)
      assert error =~ "at least one of content, embed or file"
    end

    test "returns an error if content is longer than 2000 chars", ctx do
      {:error, error} = Message.send_message(%{content: random_hex(2001)}, ctx.channel_id)
      assert error =~ "Content is too long"
    end

    test "returns the message if successful", ctx do
      {:ok, message} = Message.send_message(%{content: random_hex(2000)}, ctx.channel_id)
      assert message == Models.Message.parse(ctx.raw_message)
    end
  end

  describe "list_messages/2" do
    setup :handshake_shard

    setup do
      channel_id = random_snowflake()
      raw = message(channel_id: channel_id)
      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :get, url: ^url} -> json([raw]) end)
      [channel_id: channel_id, raw_message: raw]
    end

    test "returns an error if limit is not inside valid range", ctx do
      {:error, errors} = Message.list_messages(ctx.channel_id, %{limit: 0})
      assert_has_error(errors, "Expected limit to be between 1 and 100")

      {:error, errors} = Message.list_messages(ctx.channel_id, %{limit: 101})
      assert_has_error(errors, "Expected limit to be between 1 and 100")
    end

    test "returns an error if around is not a snowflake", ctx do
      {:error, errors} = Message.list_messages(ctx.channel_id, %{around: 10})
      assert_has_error(errors, "Expected around to be a snowflake")

      {:error, errors} = Message.list_messages(ctx.channel_id, %{around: "a"})
      assert_has_error(errors, "Expected around to be a snowflake")
    end

    test "returns an error if before is not a snowflake", ctx do
      {:error, errors} = Message.list_messages(ctx.channel_id, %{before: 10})
      assert_has_error(errors, "Expected before to be a snowflake")

      {:error, errors} = Message.list_messages(ctx.channel_id, %{before: "a"})
      assert_has_error(errors, "Expected before to be a snowflake")
    end

    test "returns an error if after is not a snowflake", ctx do
      {:error, errors} = Message.list_messages(ctx.channel_id, %{after: 10})
      assert_has_error(errors, "Expected after to be a snowflake")

      {:error, errors} = Message.list_messages(ctx.channel_id, %{after: "a"})
      assert_has_error(errors, "Expected after to be a snowflake")
    end

    test "returns an error if channel id is not a snowflake" do
      {:error, errors} = Message.list_messages(:not_a_snowflake, %{})
      assert_has_error(errors, "Expected channel_id to be a snowflake")
    end

    test "returns the list of messages", ctx do
      {:ok, messages} = Message.list_messages(ctx.channel_id, %{})
      assert messages == [Models.Message.parse(ctx.raw_message)]
    end
  end

  describe "get_message/2" do
    setup :handshake_shard

    setup do
      channel_id = random_snowflake()
      message_id = random_snowflake()
      raw = message(channel_id: channel_id, id: message_id)
      url = Client.base_url() <> "/channels/#{channel_id}/messages/#{message_id}"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)
      [channel_id: channel_id, message_id: message_id, raw_message: raw]
    end

    test "returns an error if channel_id is not a snowflake", ctx do
      {:error, errors} = Message.get_message(1324, ctx.message_id)
      assert_has_error(errors, "Expected channel_id to be a snowflake")
    end

    test "returns an error if message_id is not a snowflake", ctx do
      {:error, errors} = Message.get_message(ctx.channel_id, 1234)
      assert_has_error(errors, "Expected message_id to be a snowflake")
    end

    test "returns a message", ctx do
      {:ok, message} = Message.get_message(ctx.channel_id, ctx.message_id)
      assert message == Models.Message.parse(ctx.raw_message)
    end
  end
end
