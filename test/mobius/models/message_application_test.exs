defmodule Mobius.Models.MessageApplicationTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.MessageApplication
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == MessageApplication.parse("string")
      assert nil == MessageApplication.parse(42)
      assert nil == MessageApplication.parse(true)
      assert nil == MessageApplication.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> MessageApplication.parse()
      |> assert_field(:id, nil)
      |> assert_field(:cover_image, nil)
      |> assert_field(:description, nil)
      |> assert_field(:icon, nil)
      |> assert_field(:name, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "cover_image" => random_hex(32),
        "description" => random_hex(32),
        "icon" => random_hex(16),
        "name" => random_hex(8)
      }

      map
      |> MessageApplication.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:cover_image, map["cover_image"])
      |> assert_field(:description, map["description"])
      |> assert_field(:icon, map["icon"])
      |> assert_field(:name, map["name"])
    end
  end
end
