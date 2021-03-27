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
  setup :handshake_shard

  describe "send_message/2" do
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
end
