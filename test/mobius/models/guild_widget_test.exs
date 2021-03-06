defmodule Mobius.Models.GuildWidgetTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.GuildWidget
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == GuildWidget.parse("string")
      assert nil == GuildWidget.parse(42)
      assert nil == GuildWidget.parse(true)
      assert nil == GuildWidget.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> GuildWidget.parse()
      |> assert_field(:enabled, nil)
      |> assert_field(:channel_id, nil)
    end

    test "parses all fields as expected" do
      map = %{"enabled" => true, "channel_id" => random_snowflake()}

      map
      |> GuildWidget.parse()
      |> assert_field(:enabled, map["enabled"])
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
    end
  end
end
