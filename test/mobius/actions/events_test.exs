defmodule Mobius.Actions.EventsTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Actions.Events

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  describe "subscribe/1" do
    test "returns {:errors, [String]} if any event is invalid" do
      assert {:errors, errors} = Events.subscribe([:THIS_ISNT_AN_EVENT])
      assert ["invalid event name: :THIS_ISNT_AN_EVENT"] = errors
    end

    test "returns :ok if all event names are valid" do
      assert :ok == Events.subscribe([:GUILD_BAN_ADD, :INVITE_CREATE, :USER_UPDATE])
    end

    test "sends subscribed event to caller as a message" do
      Events.subscribe([:CHANNEL_CREATE, :WEBHOOKS_UPDATE, :CHANNEL_DELETE])
      send_payload(op: :dispatch, type: "WEBHOOKS_UPDATE")

      assert_receive {:WEBHOOKS_UPDATE, _}
    end

    test "doesn't send event if not subscribed" do
      Events.subscribe([:MESSAGE_UPDATE, :MESSAGE_DELETE])
      send_payload(op: :dispatch, type: "MESSAGE_CREATE")

      refute_receive {:MESSAGE_CREATE, _}
    end

    test "sends all events if subscribing to empty list" do
      Events.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      assert_receive {:TYPING_START, _}
    end
  end

  describe "unsubscribe/0" do
    test "returns :ok even if not subscribed" do
      assert :ok == Events.unsubscribe()
    end

    test "returns :ok when subscribed" do
      Events.subscribe()

      assert :ok == Events.unsubscribe()
    end

    test "stops sending events after unsubscribing" do
      Events.subscribe()
      send_payload(op: :dispatch, type: "TYPING_START")

      # Confirm we do receive events
      assert_receive {:TYPING_START, _}

      Events.unsubscribe()

      send_payload(op: :dispatch, type: "MESSAGE_REACTION_ADD")
      refute_receive {:MESSAGE_REACTION_ADD, _}
    end
  end
end
