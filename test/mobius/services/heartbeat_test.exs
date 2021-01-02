defmodule Mobius.Services.HeartbeatTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Opcode
  alias Mobius.Services.Heartbeat

  setup :get_shard
  setup :reset_services
  setup :stub_socket

  test "sends heartbeat regularly" do
    send_hello(50)
    assert_received_heartbeat(0)
    send_payload(op: :heartbeat_ack)

    Process.sleep(50)
    assert_received_heartbeat(0)
    send_payload(op: :heartbeat_ack)
  end

  test "sends heartbeat immediately if requested" do
    send_hello()

    assert_received_heartbeat(0)
    send_payload(op: :heartbeat)

    assert_received_heartbeat(0)
  end

  test "closes the socket if no ack since last heartbeat" do
    send_hello(50)

    assert_received_heartbeat(0)
    Process.sleep(50)
    assert_receive :socket_close, 20
  end

  test "updates ping when receives an ack", ctx do
    send_hello()

    assert_received_heartbeat(0)
    Process.sleep(50)
    send_payload(op: :heartbeat_ack)
    ping = Heartbeat.get_ping(ctx.shard)

    assert ping >= 50
  end

  defp assert_received_heartbeat(seq) do
    payload = Opcode.heartbeat(seq)
    assert_receive {:socket_msg, ^payload}
  end
end
