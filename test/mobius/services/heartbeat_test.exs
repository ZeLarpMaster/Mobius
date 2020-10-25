defmodule Mobius.Services.HeartbeatTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Heartbeat

  setup :reset_services
  setup :stub_socket

  @shard ShardInfo.new(number: 0, count: 1)

  test "sends heartbeat regularly" do
    send_hello(500)
    assert_received_heartbeat(0)
    send_payload(op: :heartbeat_ack)

    Process.sleep(500)
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
    send_hello(500)

    assert_received_heartbeat(0)
    Process.sleep(500)
    assert_receive :socket_close, 100
  end

  test "updates ping when receives an ack" do
    send_hello()

    assert_received_heartbeat(0)
    Process.sleep(50)
    send_payload(op: :heartbeat_ack)
    ping = Heartbeat.get_ping(@shard)

    assert ping >= 50
  end

  defp assert_received_heartbeat(seq) do
    payload = Opcode.heartbeat(seq)
    assert_receive {:socket_msg, ^payload}
  end
end
