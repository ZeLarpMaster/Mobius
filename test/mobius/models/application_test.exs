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
      |> check_field(:id, nil)
      |> check_field(:name, nil)
      |> check_field(:icon, nil)
      |> check_field(:description, nil)
      |> check_field(:bot_public, nil)
      |> check_field(:bot_require_code_grant, nil)
      |> check_field(:owner, nil)
      |> check_field(:team, nil)
    end

    test "parses all fields as expected" do
      map = application()

      map
      |> Application.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:name, map["name"])
      |> check_field(:icon, map["icon"])
      |> check_field(:description, map["description"])
      |> check_field(:bot_public, map["bot_public"])
      |> check_field(:bot_require_code_grant, map["bot_require_code_grant"])
      |> check_field(:owner, User.parse(map["owner"]))
      |> check_field(:team, Team.parse(map["team"]))
    end
  end
end
