defmodule Mobius.Models.MessageActivityTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.MessageActivity

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == MessageActivity.parse("string")
      assert nil == MessageActivity.parse(42)
      assert nil == MessageActivity.parse(true)
      assert nil == MessageActivity.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> MessageActivity.parse()
      |> assert_field(:type, nil)
      |> assert_field(:party_id, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "type" => 2,
        "party_id" => random_hex(16)
      }

      map
      |> MessageActivity.parse()
      |> assert_field(:type, :spectate)
      |> assert_field(:party_id, map["party_id"])
    end
  end
end
