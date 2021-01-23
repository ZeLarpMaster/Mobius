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
      |> check_field(:id, nil)
      |> check_field(:name, nil)
      |> check_field(:color, nil)
      |> check_field(:hoist, nil)
      |> check_field(:position, nil)
      |> check_field(:permissions, nil)
      |> check_field(:managed, nil)
      |> check_field(:mentionable, nil)
      |> check_field(:tags, nil)
    end

    test "parses all fields as expected" do
      map = role()

      map
      |> Role.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:name, map["name"])
      |> check_field(:color, map["color"])
      |> check_field(:hoist, map["hoist"])
      |> check_field(:position, map["position"])
      |> check_field(:permissions, Permissions.parse(map["permissions"]))
      |> check_field(:managed, map["managed"])
      |> check_field(:mentionable, map["mentionable"])
      |> check_field(:tags, RoleTags.parse(map["tags"]))
    end
  end
end
