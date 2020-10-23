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
    data = %{d: %{heartbeat_interval: 2_000}, op: Opcode.name_to_opcode(:hello), t: nil, s: nil}
    Socket.notify_payload(data, @shard)

    ctx.socket
    |> Stubs.Socket.has_message?(fn msg ->
      msg == Opcode.heartbeat(0)
    end)
    |> assert

    data = %{d: nil, t: nil, s: nil, op: Opcode.name_to_opcode(:heartbeat_ack)}
    Socket.notify_payload(data, @shard)
  end

  test "sends heartbeat immediately if requested"
  test "closes the socket if no ack since last heartbeat"
  test "updates ping when receives an ack"
end
