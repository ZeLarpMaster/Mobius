defmodule Mobius.Models.GuildPreviewTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Model
  alias Mobius.Models.Emoji
  alias Mobius.Models.GuildPreview
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == GuildPreview.parse("string")
      assert nil == GuildPreview.parse(42)
      assert nil == GuildPreview.parse(true)
      assert nil == GuildPreview.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> GuildPreview.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:icon, nil)
      |> assert_field(:splash, nil)
      |> assert_field(:discovery_splash, nil)
      |> assert_field(:emojis, nil)
      |> assert_field(:features, nil)
      |> assert_field(:approximate_member_count, nil)
      |> assert_field(:approximate_presence_count, nil)
      |> assert_field(:description, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "name" => random_hex(8),
        "icon" => random_hex(8),
        "splash" => random_hex(16),
        "discovery_splash" => random_hex(16),
        "emojis" => [emoji()],
        "features" => [random_hex(8)],
        "approximate_member_count" => :rand.uniform(500_000),
        "approximate_presence_count" => :rand.uniform(50_000),
        "description" => random_hex(16)
      }

      map
      |> GuildPreview.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:icon, map["icon"])
      |> assert_field(:splash, map["splash"])
      |> assert_field(:discovery_splash, map["discovery_splash"])
      |> assert_field(:emojis, Model.parse_list(map["emojis"], &Emoji.parse/1))
      |> assert_field(:features, map["features"])
      |> assert_field(:approximate_member_count, map["approximate_member_count"])
      |> assert_field(:approximate_presence_count, map["approximate_presence_count"])
      |> assert_field(:description, map["description"])
    end
  end
end
