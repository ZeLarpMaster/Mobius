defmodule Mobius.Models.WebhookTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Models.Webhook

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Webhook.parse("string")
      assert nil == Webhook.parse(42)
      assert nil == Webhook.parse(true)
      assert nil == Webhook.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Webhook.parse()
      |> assert_field(:id, nil)
      |> assert_field(:type, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:channel_id, nil)
      |> assert_field(:user, nil)
      |> assert_field(:name, nil)
      |> assert_field(:avatar, nil)
      |> assert_field(:token, nil)
      |> assert_field(:application_id, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "type" => 1,
        "guild_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "user" => user(),
        "name" => random_hex(8),
        "avatar" => random_hex(32),
        "token" => random_hex(32),
        "application_id" => random_snowflake()
      }

      map
      |> Webhook.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:type, :incoming)
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
      |> assert_field(:user, User.parse(map["user"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:avatar, map["avatar"])
      |> assert_field(:token, map["token"])
      |> assert_field(:application_id, Snowflake.parse(map["application_id"]))
    end
  end
end
