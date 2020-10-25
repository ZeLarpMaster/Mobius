defmodule Mobius.Services.ShardTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Core.Gateway
  alias Mobius.Core.Opcode

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  test "attempts to resume if socket closes with resumable code", ctx do
    send_payload(op: :dispatch, type: :TYPING_START, seq: 2)

    socket_closed_by_server(1001, "Going away")
    send_hello()

    resume =
      ctx.token
      |> Gateway.new()
      |> Gateway.update_seq(2)
      |> Gateway.set_session_id(ctx.session_id)
      |> Opcode.resume()

    assert_receive {:socket_msg, ^resume}
  end

  test "identifies if socket closes with unresumable code", ctx do
    socket_closed_by_server(4009, "Session timed out")
    send_hello()

    msg = Opcode.identify(ctx.shard, ctx.token)
    assert_receive {:socket_msg, ^msg}
  end

  test "exits the shard if socket closes with unrecoverable code", ctx do
    socket_closed_by_server(4013, "Invalid intent(s)")

    # TODO: Make via/1 public?
    pid = GenServer.whereis({:via, Registry, {Mobius.Registry.Shard, ctx.shard}})
    assert pid == nil
  end

  test "resumes on invalid session if possible", ctx do
    send_payload(op: :invalid_session, data: true)

    send_hello()

    resume =
      ctx.token
      |> Gateway.new()
      |> Gateway.update_seq(1)
      |> Gateway.set_session_id(ctx.session_id)
      |> Opcode.resume()

    assert_receive {:socket_msg, ^resume}
  end

  test "identifies on invalid session if can't resume", ctx do
    send_payload(op: :invalid_session, data: false)

    assert_receive :socket_close
    send_hello()

    msg = Opcode.identify(ctx.shard, ctx.token)
    assert_receive {:socket_msg, ^msg}
  end

  test "closes socket if discord requests reconnection" do
    send_payload(op: :reconnect)

    assert_receive :socket_close
  end
end
