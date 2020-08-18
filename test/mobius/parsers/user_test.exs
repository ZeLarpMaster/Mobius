defmodule Mobius.Parsers.UserTest do
  use ExUnit.Case, async: true

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_user/2 without required values" do
    %{}
    |> assert_missing_key("id", "v")
    |> Map.put("id", "123")
    |> assert_missing_key("username", "v")
    |> Map.put("username", "Alice")
    |> assert_missing_key("discriminator", "v")
    |> Map.put("discriminator", "0035")
    |> assert_missing_key("avatar", "v")
  end

  test "parse_channel/2 with minimum" do
    raw = Samples.User.raw_user(:minimal)

    user = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["username"],
      discriminator: raw["discriminator"],
      avatar: raw["avatar"]
    }

    assert user == Parsers.User.parse_user(raw)
  end

  test "parse_user/2 with everything" do
    raw = Samples.User.raw_user(:full)

    user = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["username"],
      discriminator: raw["discriminator"],
      avatar: raw["avatar"],
      bot?: raw["bot"],
      system?: raw["system"],
      mfa?: raw["mfa_enabled"],
      locale: raw["locale"],
      verified?: raw["verified"],
      email: raw["email"],
      flags: MapSet.new([:verified_bot_developer]),
      premium_type: :nitro,
      public_flags: MapSet.new([:verified_bot_developer])
    }

    assert user == Parsers.User.parse_user(raw)
  end

  defp assert_missing_key(map, key, path) do
    assert {:error, {:missing_key, key, path}} == Parsers.User.parse_user(map)
    map
  end
end
