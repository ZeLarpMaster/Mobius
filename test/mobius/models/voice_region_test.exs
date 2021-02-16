defmodule Mobius.Models.VoiceRegionTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.VoiceRegion

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == VoiceRegion.parse("string")
      assert nil == VoiceRegion.parse(42)
      assert nil == VoiceRegion.parse(true)
      assert nil == VoiceRegion.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> VoiceRegion.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:vip, nil)
      |> assert_field(:optimal, nil)
      |> assert_field(:deprecated, nil)
      |> assert_field(:custom, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_hex(8),
        "name" => random_hex(8),
        "vip" => true,
        "optimal" => true,
        "deprecated" => false,
        "custom" => false
      }

      map
      |> VoiceRegion.parse()
      |> assert_field(:id, map["id"])
      |> assert_field(:name, map["name"])
      |> assert_field(:vip, map["vip"])
      |> assert_field(:optimal, map["optimal"])
      |> assert_field(:deprecated, map["deprecated"])
      |> assert_field(:custom, map["custom"])
    end
  end
end
