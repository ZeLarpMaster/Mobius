defmodule Mobius.Models.TeamTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.Team
  alias Mobius.Models.TeamMember
  alias Mobius.Models.Utils

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Team.parse("string")
      assert nil == Team.parse(42)
      assert nil == Team.parse(true)
      assert nil == Team.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Team.parse()
      |> check_field(:id, nil)
      |> check_field(:icon, nil)
      |> check_field(:members, nil)
      |> check_field(:owner_user_id, nil)
    end

    test "parses all fields as expected" do
      map = team()

      map
      |> Team.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:icon, map["icon"])
      |> check_field(:members, Utils.parse_list(map["members"], &TeamMember.parse/1))
      |> check_field(:owner_user_id, Snowflake.parse(map["owner_user_id"]))
    end
  end
end
