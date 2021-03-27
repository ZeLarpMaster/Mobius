defmodule Mobius.Rest.MessageTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures
  import Mobius.Generators

  alias Mobius.Models
  alias Mobius.Rest
  alias Mobius.Rest.Client
  alias Tesla.Multipart

  setup :create_rest_client

  describe "send_message/3" do
    test "returns {:ok, Message.t()} if status is 200", ctx do
      body = %{
        content: random_hex(32),
        nonce: random_hex(8),
        tts: true,
        embed: embed(),
        allowed_mentions: %{},
        message_reference: %{message_id: random_snowflake()}
      }

      channel_id = random_snowflake()
      raw = message(channel_id: channel_id)
      json_body = Jason.encode!(body)

      url = Client.base_url() <> "/channels/#{channel_id}/messages"
      mock(fn %{method: :post, url: ^url, body: ^json_body} -> json(raw) end)

      assert {:ok, Models.Message.parse(raw)} ==
               Rest.Message.send_message(ctx.client, channel_id, body)
    end

    test "sends a multipart when given a file", ctx do
      file_content = random_hex(32)
      filename = "myfile.txt"
      message_content = random_hex(32)

      params = %{
        file: {file_content, filename},
        content: message_content,
        embed: embed(),
        nonce: random_hex(8),
        allowed_mentions: %{}
      }

      channel_id = random_snowflake()
      raw = message(channel_id: channel_id)
      body = Jason.encode!(Map.drop(params, [:file]))
      url = Client.base_url() <> "/channels/#{channel_id}/messages"

      mock(fn
        %{
          method: :post,
          url: ^url,
          body: %Multipart{
            parts: [
              %Multipart.Part{
                body: ^body,
                dispositions: [name: "payload_json"],
                headers: [{"content-type", "application/json"}]
              },
              %Multipart.Part{
                body: ^file_content,
                dispositions: [
                  name: "file",
                  detect_content_type: true,
                  filename: ^filename
                ]
              }
            ]
          }
        } ->
          json(raw)

        req ->
          # Makes the error easier to read if the above doesn't match
          assert false, "No match for:\n" <> inspect(req, pretty: true)
      end)

      assert {:ok, Models.Message.parse(raw)} ==
               Rest.Message.send_message(ctx.client, channel_id, params)
    end
  end
end
