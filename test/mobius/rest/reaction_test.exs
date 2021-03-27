defmodule Mobius.Rest.ReactionTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Rest
  alias Mobius.Rest.Client

  setup :create_rest_client

  describe "create_reaction/4" do
    test "returns :ok if status is 204", ctx do
      channel_id = random_snowflake()
      message_id = random_snowflake()
      emoji = "👌"

      url =
        Client.base_url() <>
          "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me"

      mock(fn %{method: :put, url: ^url} -> empty_response() end)

      assert :ok == Rest.Reaction.create_reaction(ctx.client, channel_id, message_id, emoji)
    end
  end
end
