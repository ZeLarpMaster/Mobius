defmodule Mobius.Models.BanTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Ban
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Ban.parse("string")
      assert nil == Ban.parse(42)
      assert nil == Ban.parse(true)
      assert nil == Ban.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Ban.parse()
      |> assert_field(:reason, nil)
      |> assert_field(:user, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "reason" => random_hex(16),
        "user" => user()
      }

      map
      |> Ban.parse()
      |> assert_field(:reason, map["reason"])
      |> assert_field(:user, User.parse(map["user"]))
    end
  end
end
