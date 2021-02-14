defmodule Mobius.Models.PermissionsOverwriteTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Permissions
  alias Mobius.Models.PermissionsOverwrite
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == PermissionsOverwrite.parse("string")
      assert nil == PermissionsOverwrite.parse(42)
      assert nil == PermissionsOverwrite.parse(true)
      assert nil == PermissionsOverwrite.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> PermissionsOverwrite.parse()
      |> assert_field(:id, nil)
      |> assert_field(:type, nil)
      |> assert_field(:allow, nil)
      |> assert_field(:deny, nil)
    end

    test "parses all fields as expected" do
      map = hd(channel()["permission_overwrites"])

      map
      |> PermissionsOverwrite.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:type, :role)
      |> assert_field(:allow, Permissions.parse(map["allow"]))
      |> assert_field(:deny, Permissions.parse(map["deny"]))
    end
  end
end
