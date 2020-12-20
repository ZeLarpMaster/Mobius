defmodule Mobius.Core.EventTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Event

  describe "parse_name/1" do
    test "returns atom event name for string event name" do
      assert :guild_create == Event.parse_name("GUILD_CREATE")
    end

    test "returns nil for non-event string" do
      assert nil == Event.parse_name("THIS IS NOT AN EVENT")
    end

    test "returns nil for non-strings" do
      assert nil == Event.parse_name(true)
      assert nil == Event.parse_name(42)
      assert nil == Event.parse_name(:channel_create)
      assert nil == Event.parse_name(%{})
      assert nil == Event.parse_name(["stuff"])
      assert nil == Event.parse_name({:ok, "hello"})
    end
  end

  describe "is_event_name?/1" do
    test "returns true for a valid event name" do
      assert Event.is_event_name?(:message_create)
    end

    test "returns false for non-atoms" do
      assert not Event.is_event_name?(true)
      assert not Event.is_event_name?(32)
      assert not Event.is_event_name?("MESSAGE_CREATE")
      assert not Event.is_event_name?(%{})
      assert not Event.is_event_name?(["stuff"])
      assert not Event.is_event_name?({:ok, "hello"})
    end

    test "returns false for invalid event name atom" do
      assert not Event.is_event_name?(:this_isnt_an_event)
    end
  end

  describe "parse_data/2" do
    test "raises a FunctionClauseError if the event name is invalid" do
      assert_raise FunctionClauseError, fn -> Event.parse_data(:this_isnt_an_event, nil) end
    end

    test "returns data unchanged" do
      random = random_hex(16)
      assert random == Event.parse_data(:ready, random)
    end
  end
end
