defmodule Mobius.Models.MemberTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.DateTime
  alias Mobius.Models.Member
  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Models.Utils

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Member.parse("string")
      assert nil == Member.parse(42)
      assert nil == Member.parse(true)
      assert nil == Member.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Member.parse()
      |> check_field(:user, nil)
      |> check_field(:nick, nil)
      |> check_field(:roles, nil)
      |> check_field(:joined_at, nil)
      |> check_field(:premium_since, nil)
      |> check_field(:deaf, nil)
      |> check_field(:mute, nil)
      |> check_field(:pending, nil)
    end

    test "parses all fields as expected" do
      map = member()

      map
      |> Member.parse()
      |> check_field(:user, User.parse(map["user"]))
      |> check_field(:nick, map["nick"])
      |> check_field(:roles, Utils.parse_list(map["roles"], &Snowflake.parse/1))
      |> check_field(:joined_at, DateTime.parse(map["joined_at"]))
      |> check_field(:premium_since, DateTime.parse(map["premium_since"]))
      |> check_field(:deaf, map["deaf"])
      |> check_field(:mute, map["mute"])
      |> check_field(:pending, map["pending"])
    end
  end
end
