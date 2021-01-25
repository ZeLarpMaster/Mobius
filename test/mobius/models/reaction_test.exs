defmodule Mobius.Models.ReactionTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Emoji
  alias Mobius.Models.Reaction

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Reaction.parse("string")
      assert nil == Reaction.parse(42)
      assert nil == Reaction.parse(true)
      assert nil == Reaction.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Reaction.parse()
      |> assert_field(:count, nil)
      |> assert_field(:me, nil)
      |> assert_field(:emoji, nil)
    end

    test "parses all fields as expected" do
      map = %{"count" => :rand.uniform(5000), "me" => true, "emoji" => emoji()}

      map
      |> Reaction.parse()
      |> assert_field(:count, map["count"])
      |> assert_field(:me, map["me"])
      |> assert_field(:emoji, Emoji.parse(map["emoji"]))
    end
  end
end
