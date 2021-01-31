defmodule Mobius.Models.MessageReferenceTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.MessageReference
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == MessageReference.parse("string")
      assert nil == MessageReference.parse(42)
      assert nil == MessageReference.parse(true)
      assert nil == MessageReference.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> MessageReference.parse()
      |> assert_field(:message_id, nil)
      |> assert_field(:channel_id, nil)
      |> assert_field(:guild_id, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "message_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      }

      map
      |> MessageReference.parse()
      |> assert_field(:message_id, Snowflake.parse(map["message_id"]))
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
    end
  end
end
