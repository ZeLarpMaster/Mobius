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
  setup :handshake_shard

  describe "get_channel/1" do
    setup do
      channel_id = random_snowflake()
      raw = channel(id: channel_id)
      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)
      [channel_id: channel_id, raw_channel: raw]
    end

    test "returns the channel is successful", ctx do
      {:ok, channel} = Channel.get_channel(ctx.channel_id)
      assert channel == Models.Channel.parse(ctx.raw_channel)
    end
  end
end
