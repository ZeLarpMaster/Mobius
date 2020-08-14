defmodule Mobius.Api.PinTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  test "pin_message/3", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/pins/#{message_id}"
    mock(fn %{method: :put, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Pin.pin_message(ctx.client, channel_id, message_id)
  end

  test "unpin_message/3", ctx do
    channel_id = random_snowflake()
    message_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/pins/#{message_id}"
    mock(fn %{method: :delete, url: ^url} -> {204, [], nil} end)

    assert :ok == Api.Pin.unpin_message(ctx.client, channel_id, message_id)
  end

  test "list_pins/2", ctx do
    raw = [
      Samples.Message.raw_message(:full),
      Samples.Message.raw_message(:full)
    ]

    channel_id = random_snowflake()
    url = Client.base_url() <> "/channels/#{channel_id}/pins"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, list} = Api.Pin.list_pins(ctx.client, channel_id)

    assert list == Parsers.Message.parse_message(raw)
  end
end
