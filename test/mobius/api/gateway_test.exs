defmodule Mobius.Api.GatewayTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Api
  alias Mobius.Api.Client
  alias Mobius.Parsers
  alias Mobius.Samples

  setup :create_api_client

  describe "get_bot/1" do
    test "is authorized", ctx do
      url = Client.base_url() <> "/gateway/bot"
      expected_authorization = "Bot " <> ctx.token

      mock(fn %{method: :get, url: ^url} = env ->
        case Tesla.get_header(env, "Authorization") do
          ^expected_authorization -> json(%{})
          _ -> {401, [], ""}
        end
      end)

      refute {:error, :unauthorized} == Api.Gateway.get_bot(ctx.client)
    end

    test "returns {:ok, map} if status is 200", ctx do
      raw = %{
        "url" => "wss://test.websocket.org",
        "shards" => 1,
        "session_start_limit" => %{
          "total" => 1000,
          "remaining" => 999,
          "reset_after" => 18_000_000
        }
      }

      url = Client.base_url() <> "/gateway/bot"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)

      {:ok, map} = Api.Gateway.get_bot(ctx.client)

      assert map == Parsers.Gateway.parse_gateway_bot(raw)
    end
  end

  test "get_app_info/1", ctx do
    raw = Samples.Application.raw_application(:minimal)

    url = Client.base_url() <> "/oauth2/applications/@me"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    {:ok, map} = Api.Gateway.get_app_info(ctx.client)

    assert map == Parsers.Gateway.parse_app_info(raw)
  end
end
