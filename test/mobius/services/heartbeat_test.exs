defmodule Mobius.Services.HeartbeatTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Socket
  alias Mobius.Stubs

  setup :reset_services
  setup :stub_socket

  @shard ShardInfo.new(number: 0, count: 1)

  test "sends heartbeat regularly", ctx do
    send_hello(500)
    assert_received_heartbeat(ctx.socket, 0)
    send_ack()

    Process.sleep(500)
    assert_received_heartbeat(ctx.socket, 0)
    send_ack()
  end

  test "sends heartbeat immediately if requested"
  test "closes the socket if no ack since last heartbeat"
  test "updates ping when receives an ack"

  defp assert_received_heartbeat(socket, seq) do
    socket
    |> Stubs.Socket.has_message?(fn msg ->
      msg == Opcode.heartbeat(seq)
    end)
    |> assert
  end

  defp send_ack do
    data = %{d: nil, t: nil, s: nil, op: Opcode.name_to_opcode(:heartbeat_ack)}
    Socket.notify_payload(data, @shard)
  end
end
