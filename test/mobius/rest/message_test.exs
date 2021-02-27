defmodule Mobius.Rest.MessageTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures
  import Mobius.Generators

  alias Mobius.Models
  alias Mobius.Rest
  alias Mobius.Rest.Client

  setup :create_rest_client

  describe "send_message/3" do
    test "returns {:ok, Message.t()} if status is 200", ctx do
      params = [
        content: random_hex(32),
        nonce: random_hex(8),
        tts: true,
        embed: embed(),
        allowed_mentions: %{},
        message_reference: %{message_id: random_snowflake()}
      ]

      channel_id = random_snowflake()
      raw = message(channel_id: channel_id)
      json_body = params |> Map.new() |> Jason.encode!()

      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

      assert {:ok, Models.Message.parse(raw)} ==
               Rest.Message.send_message(ctx.client, channel_id, params)
    end
  end
end
