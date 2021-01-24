defmodule Mobius.Models.UserTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == User.parse("string")
      assert nil == User.parse(42)
      assert nil == User.parse(true)
      assert nil == User.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> User.parse()
      |> assert_field(:id, nil)
      |> assert_field(:username, nil)
      |> assert_field(:discriminator, nil)
      |> assert_field(:avatar, nil)
      |> assert_field(:bot, nil)
      |> assert_field(:system, nil)
      |> assert_field(:mfa_enabled, nil)
      |> assert_field(:locale, nil)
      |> assert_field(:verified, nil)
      |> assert_field(:email, nil)
      |> assert_field(:flags, nil)
      |> assert_field(:premium_type, nil)
      |> assert_field(:public_flags, nil)
    end

    test "parses all fields as expected" do
      map = user()

      map
      |> User.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:username, map["username"])
      |> assert_field(:discriminator, map["discriminator"])
      |> assert_field(:avatar, map["avatar"])
      |> assert_field(:bot, map["bot"])
      |> assert_field(:system, map["system"])
      |> assert_field(:mfa_enabled, map["mfa_enabled"])
      |> assert_field(:locale, map["locale"])
      |> assert_field(:verified, map["verified"])
      |> assert_field(:email, map["email"])
      |> assert_field(:flags, MapSet.new([:verified_bot]))
      |> assert_field(:premium_type, :none)
      |> assert_field(:public_flags, MapSet.new([:verified_bot]))
    end
  end
end
