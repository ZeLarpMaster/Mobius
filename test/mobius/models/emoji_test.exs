defmodule Mobius.Models.EmojiTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Emoji
  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Models.Utils

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Emoji.parse("string")
      assert nil == Emoji.parse(42)
      assert nil == Emoji.parse(true)
      assert nil == Emoji.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Emoji.parse()
      |> check_field(:id, nil)
      |> check_field(:name, nil)
      |> check_field(:roles, nil)
      |> check_field(:user, nil)
      |> check_field(:require_colons, nil)
      |> check_field(:managed, nil)
      |> check_field(:animated, nil)
      |> check_field(:available, nil)
    end

    test "parses all fields as expected" do
      map = emoji()

      map
      |> Emoji.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:name, map["name"])
      |> check_field(:roles, Utils.parse_list(map["roles"], &Snowflake.parse/1))
      |> check_field(:user, User.parse(map["user"]))
      |> check_field(:require_colons, map["require_colons"])
      |> check_field(:managed, map["managed"])
      |> check_field(:animated, map["animated"])
      |> check_field(:available, map["available"])
    end
  end
end
