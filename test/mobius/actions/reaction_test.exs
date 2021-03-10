defmodule Mobius.Actions.ReactionTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Reaction
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
      emoji = "👌"

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me"

      mock(fn %{method: :put, url: ^url} -> empty_response() end)

      [message_id: message_id, channel_id: channel_id, emoji: emoji]
    end

    test "returns :ok if successful", ctx do
      :ok = Reaction.create_reaction(ctx.channel_id, ctx.message_id, ctx.emoji)
    end
  end

  describe "create_reaction/4" do
    setup do
      message_id = random_snowflake()
      channel_id = random_snowflake()
      emoji_name = "party-parrot"
      emoji_id = random_snowflake()

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji_name}:#{emoji_id}/@me"

      mock(fn %{method: :put, url: ^url} -> empty_response() end)

      [message_id: message_id, channel_id: channel_id, emoji_name: emoji_name, emoji_id: emoji_id]
    end

    test "returns :ok if successful", ctx do
      assert :ok ==
               Reaction.create_reaction(
                 ctx.channel_id,
                 ctx.message_id,
                 ctx.emoji_name,
                 ctx.emoji_id
               )
    end
  end
end
