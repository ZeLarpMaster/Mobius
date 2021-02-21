defmodule Mobius.Models.VoiceStateTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Member
  alias Mobius.Models.Snowflake
  alias Mobius.Models.VoiceState

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == VoiceState.parse("string")
      assert nil == VoiceState.parse(42)
      assert nil == VoiceState.parse(true)
      assert nil == VoiceState.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> VoiceState.parse()
      |> assert_field(:guild_id, nil)
      |> assert_field(:channel_id, nil)
      |> assert_field(:user_id, nil)
      |> assert_field(:member, nil)
      |> assert_field(:session_id, nil)
      |> assert_field(:deaf, nil)
      |> assert_field(:mute, nil)
      |> assert_field(:self_deaf, nil)
      |> assert_field(:self_mute, nil)
      |> assert_field(:self_stream, nil)
      |> assert_field(:self_video, nil)
      |> assert_field(:suppress, nil)
    end

    test "parses all fields as expected" do
      map = voice_state()

      map
      |> VoiceState.parse()
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
      |> assert_field(:user_id, Snowflake.parse(map["user_id"]))
      |> assert_field(:member, Member.parse(map["member"]))
      |> assert_field(:session_id, map["session_id"])
      |> assert_field(:deaf, map["deaf"])
      |> assert_field(:mute, map["mute"])
      |> assert_field(:self_deaf, map["self_deaf"])
      |> assert_field(:self_mute, map["self_mute"])
      |> assert_field(:self_stream, map["self_stream"])
      |> assert_field(:self_video, map["self_video"])
      |> assert_field(:suppress, map["suppress"])
    end
  end
end
