defmodule Mobius.Models.PermissionsTest do
  use ExUnit.Case, async: true

  alias Mobius.Models.Permissions

  describe "parse/1" do
    test "returns nil for non-strings" do
      assert nil == Permissions.parse(%{})
      assert nil == Permissions.parse([])
      assert nil == Permissions.parse(42)
      assert nil == Permissions.parse(true)
      assert nil == Permissions.parse(nil)
    end

    test "returns nil for non-numeric strings" do
      assert nil == Permissions.parse("123.45")
      assert nil == Permissions.parse("abc")
    end

    test "returns empty set for 0" do
      assert MapSet.new() == Permissions.parse("0")
    end

    test "returns MapSet of permissions for numeric string" do
      [:manage_emojis, :send_messages, :view_channel, :create_instant_invite]
      |> MapSet.new()
      |> MapSet.equal?(Permissions.parse("1073744897"))
      |> assert
    end
  end
end
