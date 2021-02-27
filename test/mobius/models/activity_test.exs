defmodule Mobius.Models.ActivityTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Activity
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Activity.parse("string")
      assert nil == Activity.parse(42)
      assert nil == Activity.parse(true)
      assert nil == Activity.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Activity.parse()
      |> assert_field(:name, nil)
      |> assert_field(:type, nil)
      |> assert_field(:url, nil)
      |> assert_field(:created_at, nil)
      |> assert_field(:timestamps, nil)
      |> assert_field(:application_id, nil)
      |> assert_field(:details, nil)
      |> assert_field(:state, nil)
      |> assert_field(:emoji, nil)
      |> assert_field(:party, nil)
      |> assert_field(:assets, nil)
      |> assert_field(:secrets, nil)
      |> assert_field(:instance, nil)
      |> assert_field(:flags, nil)
    end

    test "parses all fields as expected" do
      map = activity()

      map
      |> Activity.parse()
      |> assert_field(:name, map["name"])
      |> assert_field(:type, :custom)
      |> assert_field(:url, map["url"])
      |> assert_field(:created_at, DateTime.from_unix!(map["created_at"], :millisecond))
      |> assert_field(:timestamps, map["timestamps"])
      |> assert_field(:application_id, Snowflake.parse(map["application_id"]))
      |> assert_field(:details, map["details"])
      |> assert_field(:state, map["state"])
      |> assert_field(:emoji, map["emoji"])
      |> assert_field(:party, map["party"])
      |> assert_field(:assets, map["assets"])
      |> assert_field(:secrets, map["secrets"])
      |> assert_field(:instance, map["instance"])
      |> assert_field(:flags, MapSet.new([:join, :spectate, :play]))
    end
  end
end
