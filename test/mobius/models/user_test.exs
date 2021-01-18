defmodule Mobius.Models.UserTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures

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
      |> check_field(:id, nil)
      |> check_field(:username, nil)
      |> check_field(:discriminator, nil)
      |> check_field(:avatar, nil)
      |> check_field(:bot, nil)
      |> check_field(:system, nil)
      |> check_field(:mfa_enabled, nil)
      |> check_field(:locale, nil)
      |> check_field(:verified, nil)
      |> check_field(:email, nil)
      |> check_field(:flags, nil)
      |> check_field(:premium_type, nil)
      |> check_field(:public_flags, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "id" => random_snowflake(),
        "username" => random_hex(8),
        "discriminator" => "#{:rand.uniform(9999)}",
        "avatar" => random_hex(8),
        "bot" => true,
        "system" => false,
        "mfa_enabled" => false,
        "locale" => "en_US",
        "verified" => false,
        "email" => nil,
        "flags" => Bitwise.<<<(1, 16),
        "premium_type" => 0,
        "public_flags" => Bitwise.<<<(1, 16)
      }

      map
      |> User.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:username, map["username"])
      |> check_field(:discriminator, map["discriminator"])
      |> check_field(:avatar, map["avatar"])
      |> check_field(:bot, map["bot"])
      |> check_field(:system, map["system"])
      |> check_field(:mfa_enabled, map["mfa_enabled"])
      |> check_field(:locale, map["locale"])
      |> check_field(:verified, map["verified"])
      |> check_field(:email, map["email"])
      |> check_field(:flags, MapSet.new([:verified_bot]))
      |> check_field(:premium_type, :none)
      |> check_field(:public_flags, MapSet.new([:verified_bot]))
    end
  end

  defp check_field(struct, field, expected_value) do
    assert Map.fetch!(struct, field) == expected_value
    struct
  end
end
