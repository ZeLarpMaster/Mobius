defmodule Mobius.Models.ApplicationTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Application
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Team
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Application.parse("string")
      assert nil == Application.parse(42)
      assert nil == Application.parse(true)
      assert nil == Application.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Application.parse()
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:icon, nil)
      |> assert_field(:description, nil)
      |> assert_field(:bot_public, nil)
      |> assert_field(:bot_require_code_grant, nil)
      |> assert_field(:owner, nil)
      |> assert_field(:team, nil)
    end

    test "parses all fields as expected" do
      map = application()

      map
      |> Application.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:icon, map["icon"])
      |> assert_field(:description, map["description"])
      |> assert_field(:bot_public, map["bot_public"])
      |> assert_field(:bot_require_code_grant, map["bot_require_code_grant"])
      |> assert_field(:owner, User.parse(map["owner"]))
      |> assert_field(:team, Team.parse(map["team"]))
    end
  end
end
