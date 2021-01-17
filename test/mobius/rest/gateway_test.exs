defmodule Mobius.Rest.GatewayTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Models
  alias Mobius.Rest
  alias Mobius.Rest.Client

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

    test "returns {:ok, GatewayBot.t()} if status is 200", ctx do
      raw = %{
        "url" => "wss://test.websocket.org",
        "shards" => 1,
        "session_start_limit" => %{
          "total" => 1000,
          "remaining" => 999,
          "reset_after" => 18_000_000,
          "max_concurrency" => 1
        }
      }

      url = Client.base_url() <> "/gateway/bot"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)

      assert {:ok, Models.GatewayBot.parse(raw)} == Rest.Gateway.get_bot(ctx.client)
    end
  end

  test "get_app_info/1", ctx do
    owner_id = random_snowflake()
    team_id = random_snowflake()

    raw = %{
      "bot_public" => false,
      "bot_require_code_grant" => false,
      "description" => "My cool bot application",
      "icon" => random_hex(32),
      "id" => random_snowflake(),
      "name" => "My Bot",
      "owner" => %{
        "id" => team_id,
        "username" => "team#{team_id}",
        "avatar" => random_hex(32),
        "discriminator" => "0000",
        # Team flag is enabled for both public_flags and flags
        "flags" => 1024,
        "public_flags" => 1024
      },
      "summary" => "",
      "team" => %{
        "icon" => random_hex(32),
        "id" => team_id,
        "members" => [
          %{
            "membership_state" => 2,
            "permissions" => ["*"],
            "team_id" => team_id,
            "user" => %{
              "avatar" => random_hex(32),
              "discriminator" => "#{:rand.uniform(9999)}",
              "id" => owner_id,
              "public_flags" => 0,
              "username" => random_hex(8)
            }
          }
        ],
        "name" => random_hex(8),
        "owner_user_id" => owner_id
      },
      "verify_key" => random_hex(64)
    }

    url = Client.base_url() <> "/oauth2/applications/@me"
    mock(fn %{method: :get, url: ^url} -> json(raw) end)

    assert {:ok, Models.Application.parse(raw)} == Rest.Gateway.get_app_info(ctx.client)
  end
end
