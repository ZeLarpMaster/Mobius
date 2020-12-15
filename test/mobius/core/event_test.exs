defmodule Mobius.Core.EventTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Event

  describe "parse_name/1" do
    test "returns atom event name for string event name" do
      assert :GUILD_CREATE == Event.parse_name("GUILD_CREATE")
    end

    test "returns nil for event name atoms" do
      assert nil == Event.parse_name(:CHANNEL_CREATE)
    end

    test "returns nil for non-event string" do
      assert nil == Event.parse_name("THIS IS NOT AN EVENT")
    end

    test "returns nil for number" do
      assert nil == Event.parse_name(42)
    end
  end

  describe "is_event_name?/1" do
    test "returns true for a valid event name" do
      assert Event.is_event_name?(:MESSAGE_CREATE)
    end

    test "returns false for the string of an event name" do
      assert not Event.is_event_name?("MESSAGE_CREATE")
    end

    test "returns false for non-atoms" do
      assert not Event.is_event_name?(32)
    end

    test "returns false for invalid event name atom" do
      assert not Event.is_event_name?(:THIS_IS_NOT_AN_EVENT)
    end
  end

  describe "parse_data/2" do
    test "returns data unchanged" do
      random = random_hex(16)
      assert random == Event.parse_data(:READY, random)
    end
  end
end
