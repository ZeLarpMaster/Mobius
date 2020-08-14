defmodule Mobius.Parsers.GatewayTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_gateway_bot/1 everything there" do
    input = %{
      "url" => "some url",
      "shards" => 1,
      "session_start_limit" => %{
        "total" => 1000,
        "remaining" => 999,
        "reset_after" => 18_000_000
      }
    }

    output = Parsers.Gateway.parse_gateway_bot(input)

    assert output.url == "some url"
    assert output.shards == 1
    assert output.session_start_limit.total == 1000
    assert output.session_start_limit.remaining == 999
    assert output.session_start_limit.reset_after == 18_000_000
  end

  test "parse_gateway_bot/1 returns error when missing values" do
    assert {:error, :invalid_input} == Parsers.Gateway.parse_gateway_bot(nil)

    %{}
    |> assert_missing_key("url", "v")
    |> Map.put("url", "wss://test.websocket.org")
    |> assert_missing_key("shards", "v")
    |> Map.put("shards", 1)
    |> assert_missing_key("session_start_limit", "v")
    |> Map.put("session_start_limit", %{})
    |> assert_missing_key("total", "v.session_start_limit")
    |> Map.put("session_start_limit", %{"total" => 1000})
    |> assert_missing_key("remaining", "v.session_start_limit")
  end

  test "parse_app_info/1 with minimal info" do
    raw = Samples.Application.raw_application(:minimal)

    app = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"],
      icon: raw["icon"],
      description: raw["description"],
      bot_public?: false,
      bot_require_code_grant?: false,
      owner: Parsers.User.parse_user(raw["owner"]),
      summary: raw["summary"],
      verify_key: raw["verify_key"],
      team: nil
    }

    assert app == Parsers.Gateway.parse_app_info(raw)
  end

  test "parse_app_info/1 with full info" do
    raw = Samples.Application.raw_application(:full)

    app = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"],
      icon: raw["icon"],
      description: raw["description"],
      bot_public?: false,
      bot_require_code_grant?: false,
      owner: Parsers.User.parse_user(raw["owner"]),
      summary: raw["summary"],
      verify_key: raw["verify_key"],
      team: %{
        icon: raw["team"]["icon"],
        id: Parsers.Utils.parse_snowflake(raw["team"]["id"]),
        members: [
          %{
            membership_state: :accepted,
            permissions: ["*"],
            team_id: Parsers.Utils.parse_snowflake(Enum.at(raw["team"]["members"], 0)["team_id"]),
            user: Parsers.User.parse_user(Enum.at(raw["team"]["members"], 0)["user"])
          }
        ],
        owner_user_id: Parsers.Utils.parse_snowflake(raw["team"]["owner_user_id"])
      }
    }

    assert app == Parsers.Gateway.parse_app_info(raw)
  end

  defp assert_missing_key(map, key, path) do
    assert {:error, {:missing_key, key, path}} == Parsers.Gateway.parse_gateway_bot(map)
    map
  end
end
