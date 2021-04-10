defmodule Mobius.Actions.ChannelTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Channel
  alias Mobius.Models
  alias Mobius.Rest.Client

  setup :reset_services
  setup :create_rest_client
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard

  test "get/1 when the bot isn't ready" do
    {:error, error} = Channel.get(random_snowflake())
    assert error =~ "must be ready"
  end

  describe "get/1 when the bot is ready" do
    setup :handshake_shard

    setup do
      channel_id = random_snowflake()
      raw = channel(id: channel_id)
      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)
      [channel_id: channel_id, raw_channel: raw]
    end

    test "returns the channel is successful", ctx do
      {:ok, channel} = Channel.get(ctx.channel_id)
      assert channel == Models.Channel.parse(ctx.raw_channel)
    end
  end
end
