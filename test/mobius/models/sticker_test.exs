defmodule Mobius.Models.StickerTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.Sticker

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Sticker.parse("string")
      assert nil == Sticker.parse(42)
      assert nil == Sticker.parse(true)
      assert nil == Sticker.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Sticker.parse()
      |> assert_field(:id, nil)
      |> assert_field(:pack_id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:description, nil)
      |> assert_field(:tags, nil)
      |> assert_field(:asset, nil)
      |> assert_field(:preview_asset, nil)
      |> assert_field(:format_type, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "pack_id" => random_snowflake(),
        "name" => random_hex(8),
        "description" => random_hex(16),
        "tags" => "abc,def",
        "asset" => random_hex(8),
        "preview_asset" => random_hex(8),
        "format_type" => 2
      }

      map
      |> Sticker.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:pack_id, Snowflake.parse(map["pack_id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:description, map["description"])
      |> assert_field(:tags, ["abc", "def"])
      |> assert_field(:asset, map["asset"])
      |> assert_field(:preview_asset, map["preview_asset"])
      |> assert_field(:format_type, :apng)
    end
  end
end
