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
      EventPipeline.subscribe([:CHANNEL_CREATE, :WEBHOOKS_UPDATE, :CHANNEL_DELETE])
      send_payload(op: :dispatch, type: "WEBHOOKS_UPDATE")

      assert_receive {:WEBHOOKS_UPDATE, _}
    end

    test "doesn't send event if not subscribed" do
      EventPipeline.subscribe([:MESSAGE_UPDATE, :MESSAGE_DELETE])
      send_payload(op: :dispatch, type: "MESSAGE_CREATE")

      refute_receive {:MESSAGE_CREATE, _}
    end

    test "sends all events if subscribing to empty list" do
      EventPipeline.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      assert_receive {:TYPING_START, _}
    end
  end

  describe "unsubscribe/0" do
    test "stops sending events after unsubscribing" do
      EventPipeline.subscribe([])
      send_payload(op: :dispatch, type: "TYPING_START")

      # Confirm we do receive events
      assert_receive {:TYPING_START, _}

      EventPipeline.unsubscribe()

      send_payload(op: :dispatch, type: "MESSAGE_REACTION_ADD")
      refute_receive {:MESSAGE_REACTION_ADD, _}
    end
  end
end
