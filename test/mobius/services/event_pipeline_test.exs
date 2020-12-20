defmodule Mobius.Services.EventPipelineTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Services.EventPipeline

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  describe "subscribe/1" do
    test "sends subscribed event to caller as a message" do
      EventPipeline.subscribe([:channel_create, :webhooks_update, :channel_delete])
      send_payload(op: :dispatch, type: "WEBHOOKS_UPDATE")

      assert_receive {:webhooks_update, _}
    end

    test "doesn't send event if not subscribed" do
      EventPipeline.subscribe([:message_update, :message_delete])
      send_payload(op: :dispatch, type: "MESSAGE_CREATE")

      refute_receive {:message_create, _}
    end

    test "sends all events if subscribing to empty list" do
      EventPipeline.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      assert_receive {:typing_start, _}
    end
  end

  describe "unsubscribe/0" do
    test "stops sending events after unsubscribing" do
      EventPipeline.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      # Confirm we do receive events
      assert_receive {:typing_start, _}

      EventPipeline.unsubscribe()

      send_payload(op: :dispatch, type: "MESSAGE_REACTION_ADD")
      refute_receive {:message_reaction_add, _}
    end
  end
end
