defmodule Mobius.Models.TeamMemberTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.TeamMember
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == TeamMember.parse("string")
      assert nil == TeamMember.parse(42)
      assert nil == TeamMember.parse(true)
      assert nil == TeamMember.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> TeamMember.parse()
      |> check_field(:membership_state, nil)
      |> check_field(:permissions, nil)
      |> check_field(:team_id, nil)
      |> check_field(:user, nil)
    end

    test "parses all fields as expected" do
      map = team_member()

      map
      |> TeamMember.parse()
      |> check_field(:membership_state, :accepted)
      |> check_field(:permissions, ["*"])
      |> check_field(:team_id, Snowflake.parse(map["team_id"]))
      |> check_field(:user, User.parse(map["user"]))
    end
  end
end
