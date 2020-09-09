defmodule Mobius.Core.Rest.GatewayTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Core.Rest
  alias Mobius.Core.Rest.Client

  setup :create_token
  setup :create_rest_client

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

      refute {:error, :unauthorized} == Rest.Gateway.get_bot(ctx.client)
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

      assert {:ok, raw} == Rest.Gateway.get_bot(ctx.client)
    end
  end

  test "get_app_info/1", ctx do
    raw = %{
      "field" => "value"
    }

    url = Client.base_url() <> "/oauth2/applications/@me"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    assert {:ok, raw} == Rest.Gateway.get_app_info(ctx.client)
  end
end
