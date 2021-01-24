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
      |> assert_field(:membership_state, nil)
      |> assert_field(:permissions, nil)
      |> assert_field(:team_id, nil)
      |> assert_field(:user, nil)
    end

    test "parses all fields as expected" do
      map = team_member()

      map
      |> TeamMember.parse()
      |> assert_field(:membership_state, :accepted)
      |> assert_field(:permissions, ["*"])
      |> assert_field(:team_id, Snowflake.parse(map["team_id"]))
      |> assert_field(:user, User.parse(map["user"]))
    end
  end
end
