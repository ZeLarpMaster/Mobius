defmodule Mobius.Models.RoleTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Permissions
  alias Mobius.Models.Role
  alias Mobius.Models.RoleTags
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Role.parse("string")
      assert nil == Role.parse(42)
      assert nil == Role.parse(true)
      assert nil == Role.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Role.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:color, nil)
      |> assert_field(:hoist, nil)
      |> assert_field(:position, nil)
      |> assert_field(:permissions, nil)
      |> assert_field(:managed, nil)
      |> assert_field(:mentionable, nil)
      |> assert_field(:tags, nil)
    end

    test "parses all fields as expected" do
      map = role()

      map
      |> Role.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:color, map["color"])
      |> assert_field(:hoist, map["hoist"])
      |> assert_field(:position, map["position"])
      |> assert_field(:permissions, Permissions.parse(map["permissions"]))
      |> assert_field(:managed, map["managed"])
      |> assert_field(:mentionable, map["mentionable"])
      |> assert_field(:tags, RoleTags.parse(map["tags"]))
    end
  end
end
