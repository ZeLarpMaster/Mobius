defmodule Mobius.Models.ChannelMentionTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.ChannelMention
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == ChannelMention.parse("string")
      assert nil == ChannelMention.parse(42)
      assert nil == ChannelMention.parse(true)
      assert nil == ChannelMention.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> ChannelMention.parse()
      |> assert_field(:id, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:type, nil)
      |> assert_field(:name, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "type" => 0,
        "name" => random_hex(8)
      }

      map
      |> ChannelMention.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:type, :guild_text)
      |> assert_field(:name, map["name"])
    end
  end
end
