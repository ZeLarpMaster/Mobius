defmodule Mobius.Actions.MessageTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
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

    test "returns an error if neither content or embed is given", ctx do
      {:error, error} = Message.send_message(%{}, ctx.channel_id)
      assert error =~ "at least one of content or embed"
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
end
