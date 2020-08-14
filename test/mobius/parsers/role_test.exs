defmodule Mobius.Parsers.RoleTest do
  use ExUnit.Case

  alias Mobius.Samples
  alias Mobius.Parsers

  test "parse_role/2 all attributes are required" do
    %{}
    |> assert_missing_key("id", "v")
    |> Map.put("id", "123")
    |> assert_missing_key("name", "v")
    |> Map.put("name", "new role")
    |> assert_missing_key("color", "v")
    |> Map.put("color", 0)
    |> assert_missing_key("hoist", "v")
    |> Map.put("hoist", false)
    |> assert_missing_key("position", "v")
    |> Map.put("position", 0)
    |> assert_missing_key("permissions", "v")
    |> Map.put("permissions", 0)
    |> assert_missing_key("managed", "v")
    |> Map.put("managed", false)
    |> assert_missing_key("mentionable", "v")
    |> Map.put("mentionable", false)
    |> Parsers.Role.parse_role()
    |> is_map()
    |> assert
  end

  test "parse_role/2 with everything" do
    raw = Samples.Role.raw_role(:full)

    role = %{
      id: Parsers.Utils.parse_snowflake(raw["id"]),
      name: raw["name"],
      color: raw["color"],
      hoisted?: raw["hoist"],
      position: raw["position"],
      permissions: raw["permissions"],
      managed?: raw["managed"],
      mentionable?: raw["mentionable"]
    }

    assert role == Parsers.Role.parse_role(raw)
  end

  defp assert_missing_key(map, key, path) do
    assert {:error, {:missing_key, key, path}} == Parsers.Role.parse_role(map)
    map
  end
end
