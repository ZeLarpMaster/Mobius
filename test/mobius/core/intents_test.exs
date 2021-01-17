defmodule Mobius.Core.IntentsTest do
  use ExUnit.Case, async: true

  alias Mobius.Core.Intents
  alias Mobius.TestUtils

  @passthrough_events [
    :hello,
    :ready,
    :resumed,
    :reconnect,
    :invalid_session,
    :guild_members_chunk,
    :user_update,
    :voice_server_update
  ]

  describe "filter_privileged_intents/2" do
    test "returns empty set for non-privileged intents" do
      [:guild_messages, :direct_messages, :guild_voice_states]
      |> MapSet.new()
      |> Intents.filter_privileged_intents()
      |> Enum.empty?()
      |> assert
    end

    test "returns only the privileged intents from intents containing them" do
      Intents.all_intents()
      |> Intents.filter_privileged_intents()
      |> MapSet.equal?(MapSet.new([:guild_members, :guild_presences]))
      |> assert
    end
  end

  describe "events_for_intents/1" do
    test "returns the passthrough events for empty intents" do
      MapSet.new()
      |> Intents.events_for_intents()
      |> TestUtils.assert_list_unordered(@passthrough_events)
    end

    test "returns the events only once even if multiple intents allow it" do
      [:guild_message_typing, :direct_message_typing]
      |> MapSet.new()
      |> Intents.events_for_intents()
      |> TestUtils.assert_list_unordered(@passthrough_events ++ [:typing_start])
    end
  end

  describe "has_intent_for_event?/2" do
    test "returns true for passthrough events" do
      assert Intents.has_intent_for_event?(:guild_members_chunk, MapSet.new())
    end

    test "returns true if intents contain any of the required intents" do
      assert Intents.has_intent_for_event?(:message_create, MapSet.new([:guild_messages]))
    end

    test "returns false if the required intent isn't in the intents" do
      assert not Intents.has_intent_for_event?(:message_create, MapSet.new([:guild_webhooks]))
    end
  end
end
