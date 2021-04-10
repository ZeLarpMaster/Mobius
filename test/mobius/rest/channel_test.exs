defmodule Mobius.Rest.ChannelTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures
  import Mobius.Generators

  alias Mobius.Models
  alias Mobius.Rest
  alias Mobius.Rest.Client

  setup :create_rest_client

  describe "get/2" do
    test "returns {:ok, Channel.t()} if status is 200", ctx do
      channel_id = random_snowflake()
      raw = channel(channel_id: channel_id)

      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)

      assert {:ok, Models.Channel.parse(raw)} == Rest.Channel.get(ctx.client, channel_id)
    end
  end
end
