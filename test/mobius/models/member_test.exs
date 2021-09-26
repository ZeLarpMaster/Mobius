defmodule Mobius.Models.MemberTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Model
  alias Mobius.Models.Member
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

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
      |> assert_field(:user, nil)
      |> assert_field(:nick, nil)
      |> assert_field(:roles, nil)
      |> assert_field(:joined_at, nil)
      |> assert_field(:premium_since, nil)
      |> assert_field(:deaf, nil)
      |> assert_field(:mute, nil)
      |> assert_field(:pending, nil)
    end

    test "parses all fields as expected" do
      map = member()

      map
      |> Member.parse()
      |> assert_field(:user, User.parse(map["user"]))
      |> assert_field(:nick, map["nick"])
      |> assert_field(:roles, Model.parse_list(map["roles"], &Snowflake.parse/1))
      |> assert_field(:joined_at, Timestamp.parse(map["joined_at"]))
      |> assert_field(:premium_since, Timestamp.parse(map["premium_since"]))
      |> assert_field(:deaf, map["deaf"])
      |> assert_field(:mute, map["mute"])
      |> assert_field(:pending, map["pending"])
    end
  end
end
