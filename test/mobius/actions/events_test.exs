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
      assert {:errors, errors} = Events.subscribe([:this_isnt_an_event])
      assert ["invalid event name: :this_isnt_an_event"] = errors
    end

    test "returns :ok if all event names are valid" do
      assert :ok == Events.subscribe([:guild_ban_add, :invite_create, :user_update])
    end

    test "sends subscribed event to caller as a message" do
      Events.subscribe([:channel_create, :webhooks_update, :channel_delete])
      send_payload(op: :dispatch, type: "WEBHOOKS_UPDATE")

      assert_receive {:webhooks_update, _}
    end

    test "doesn't send event if not subscribed" do
      Events.subscribe([:message_update, :message_delete])
      send_payload(op: :dispatch, type: "MESSAGE_CREATE")

      refute_receive {:message_create, _}
    end

    test "sends all events if subscribing to empty list" do
      Events.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      assert_receive {:typing_start, _}
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
      assert_receive {:typing_start, _}

      Events.unsubscribe()

      send_payload(op: :dispatch, type: "MESSAGE_REACTION_ADD")
      refute_receive {:message_reaction_add, _}
    end
  end
end
