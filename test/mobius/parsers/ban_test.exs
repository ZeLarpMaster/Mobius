defmodule Mobius.Parsers.BanTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_ban/2 without required values" do
    %{}
    |> assert_missing_key("reason", "v")
    |> Map.put("reason", "something")
    |> assert_missing_key("user", "v")
    |> Map.put("user", Samples.User.raw_user(:minimal))
    |> Parsers.Ban.parse_ban()
    |> is_map()
    |> assert
  end

  test "parse_ban/2" do
    raw = %{
      "reason" => random_hex(8),
      "user" => Samples.User.raw_user(:minimal)
    }

    ban = %{
      reason: raw["reason"],
      user: Parsers.User.parse_user(raw["user"])
    }

    assert ban == Parsers.Ban.parse_ban(raw)
  end

  defp assert_missing_key(map, key, path) do
    assert {:error, {:missing_key, key, path}} == Parsers.Ban.parse_ban(map)
    map
  end
end
