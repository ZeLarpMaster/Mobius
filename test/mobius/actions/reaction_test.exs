defmodule Mobius.Actions.ReactionTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Reaction
  alias Mobius.Models.Emoji
  alias Mobius.Rest.Client

  setup :reset_services
  setup :create_rest_client
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard
  setup :handshake_shard

  describe "create_reaction/3" do
    setup do
      message_id = random_snowflake()
      channel_id = random_snowflake()
      emoji = Emoji.parse(emoji())

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{Emoji.get_identifier(emoji)}/@me"

      mock(fn %{method: :put, url: ^url} -> empty_response() end)

      [message_id: message_id, channel_id: channel_id, emoji: emoji]
    end

    test "returns :ok if successful", ctx do
      :ok = Reaction.create_reaction(ctx.emoji, ctx.channel_id, ctx.message_id)
    end
  end
end
