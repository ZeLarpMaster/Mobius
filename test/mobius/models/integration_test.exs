defmodule Mobius.Models.IntegrationTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Integration
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Integration.parse("string")
      assert nil == Integration.parse(42)
      assert nil == Integration.parse(true)
      assert nil == Integration.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Integration.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:type, nil)
      |> assert_field(:enabled, nil)
      |> assert_field(:syncing, nil)
      |> assert_field(:role_id, nil)
      |> assert_field(:enable_emoticons, nil)
      |> assert_field(:expire_behavior, nil)
      |> assert_field(:expire_grace_period, nil)
      |> assert_field(:user, nil)
      |> assert_field(:account, nil)
      |> assert_field(:synced_at, nil)
      |> assert_field(:subscriber_count, nil)
      |> assert_field(:revoked, nil)
      |> assert_field(:application, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "name" => random_hex(8),
        "type" => "twitch",
        "enabled" => true,
        "syncing" => false,
        "role_id" => random_snowflake(),
        "enable_emoticons" => true,
        "expire_behavior" => 1,
        "expire_grace_period" => :rand.uniform(365),
        "user" => user(),
        "account" => %{
          "id" => random_hex(16),
          "name" => random_hex(32)
        },
        "synced_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "subscriber_count" => :rand.uniform(100_000),
        "revoked" => false,
        "application" => %{
          "id" => random_snowflake(),
          "name" => random_hex(16),
          "icon" => random_hex(16),
          "description" => random_hex(32),
          "summary" => random_hex(32),
          "bot" => user()
        }
      }

      map
      |> Integration.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:type, :twitch)
      |> assert_field(:enabled, map["enabled"])
      |> assert_field(:syncing, map["syncing"])
      |> assert_field(:role_id, Snowflake.parse(map["role_id"]))
      |> assert_field(:enable_emoticons, map["enable_emoticons"])
      |> assert_field(:expire_behavior, :kick)
      |> assert_field(:expire_grace_period, map["expire_grace_period"])
      |> assert_field(:user, User.parse(map["user"]))
      |> assert_field(:account, Integration.Account.parse(map["account"]))
      |> assert_field(:synced_at, Timestamp.parse(map["synced_at"]))
      |> assert_field(:subscriber_count, map["subscriber_count"])
      |> assert_field(:revoked, map["revoked"])
      |> assert_field(:application, Integration.Application.parse(map["application"]))
    end
  end
end
