defmodule Mobius.Actions.ReactionTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils
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

  describe "delete_own_reaction/3" do
    setup do
      message_id = random_snowflake()
      channel_id = random_snowflake()
      emoji = Emoji.parse(emoji())

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{Emoji.get_identifier(emoji)}/@me"

      mock(fn %{method: :delete, url: ^url} -> empty_response() end)

      [message_id: message_id, channel_id: channel_id, emoji: emoji]
    end

    test "returns :ok if successful", ctx do
      :ok = Reaction.delete_own_reaction(ctx.emoji, ctx.channel_id, ctx.message_id)
    end

    test "returns an error if emoji is not an emoji" do
      {:error, errors} = Reaction.delete_own_reaction("", "", "")
      assert_has_error(errors, "Expected emoji to be an emoji")
    end

    test "returns an error if channel_id is not a snowflake" do
      {:error, errors} = Reaction.delete_own_reaction(%{}, :not_a_snowflake, "")
      assert_has_error(errors, "Expected channel_id to be a snowflake")
    end

    test "returns an error if message_id is not a snowflake" do
      {:error, errors} = Reaction.delete_own_reaction(%{}, "1", :not_a_snowflake)
      assert_has_error(errors, "Expected message_id to be a snowflake")
    end
  end
end
