defmodule Mobius.Models.StageInstanceTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.StageInstance

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == StageInstance.parse("string")
      assert nil == StageInstance.parse(42)
      assert nil == StageInstance.parse(true)
      assert nil == StageInstance.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> StageInstance.parse()
      |> assert_field(:id, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:channel_id, nil)
      |> assert_field(:topic, nil)
    end

    test "parses all fields as expected" do
      map = stage_instance()

      map
      |> StageInstance.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
      |> assert_field(:topic, map["topic"])
    end
  end
end
