defmodule Mobius.Models.EmojiTest do
  use ExUnit.Case, async: true
  doctest Mobius.Models.Emoji

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Model
  alias Mobius.Models.Emoji
  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

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
      |> assert_field(:id, nil)
      |> assert_field(:name, nil)
      |> assert_field(:roles, nil)
      |> assert_field(:user, nil)
      |> assert_field(:require_colons, nil)
      |> assert_field(:managed, nil)
      |> assert_field(:animated, nil)
      |> assert_field(:available, nil)
    end

    test "parses all fields as expected" do
      map = emoji()

      map
      |> Emoji.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:roles, Model.parse_list(map["roles"], &Snowflake.parse/1))
      |> assert_field(:user, User.parse(map["user"]))
      |> assert_field(:require_colons, map["require_colons"])
      |> assert_field(:managed, map["managed"])
      |> assert_field(:animated, map["animated"])
      |> assert_field(:available, map["available"])
    end
  end
end
