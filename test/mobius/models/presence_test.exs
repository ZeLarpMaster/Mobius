defmodule Mobius.Models.PresenceTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Activity
  alias Mobius.Models.Presence
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Utils

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Presence.parse("string")
      assert nil == Presence.parse(42)
      assert nil == Presence.parse(true)
      assert nil == Presence.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Presence.parse()
      |> assert_field(:user_id, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:status, nil)
      |> assert_field(:activities, nil)
      |> assert_field(:client_status, nil)
    end

    test "parses all fields as expected" do
      map = presence()

      map
      |> Presence.parse()
      |> assert_field(:user_id, Snowflake.parse(map["user"]["id"]))
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:status, :online)
      |> assert_field(:activities, Utils.parse_list(map["activities"], &Activity.parse/1))
      |> assert_field(:client_status, %{
        "desktop" => :idle,
        "mobile" => :dnd,
        "web" => :offline
      })
    end
  end
end
