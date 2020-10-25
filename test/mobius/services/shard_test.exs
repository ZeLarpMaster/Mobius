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

    # Shard will attempt to resume when closed with code 1001 (Going away)
    # See Mobius.Core.SocketCodes for the list of codes
    close_socket_from_server(1001, "Going away")
    send_hello()

    resume = make_resume_payload(ctx, 2)
    assert_receive {:socket_msg, ^resume}
  end

  test "identifies if socket closes with unresumable code", ctx do
    # Shard won't attempt to resume, but will reconnect when closed with code 4009 (Session timed out)
    # See Mobius.Core.SocketCodes for the list of codes
    close_socket_from_server(4009, "Session timed out")
    send_hello()

    msg = Opcode.identify(ctx.shard, ctx.token)
    assert_receive {:socket_msg, ^msg}
  end

  test "exits the shard if socket closes with unrecoverable code", ctx do
    # Shard will completely disconnect when closed with code 4013 (Invalid intent(s))
    # See Mobius.Core.SocketCodes for the list of codes
    close_socket_from_server(4013, "Invalid intent(s)")

    # TODO: Make via/1 public?
    pid = GenServer.whereis({:via, Registry, {Mobius.Registry.Shard, ctx.shard}})
    assert pid == nil
  end

  test "resumes on invalid session if possible", ctx do
    send_payload(op: :invalid_session, data: true)

    send_hello()

    resume = make_resume_payload(ctx, 1)
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

  defp make_resume_payload(ctx, seq) do
    ctx.token
    |> Gateway.new()
    |> Gateway.update_seq(seq)
    |> Gateway.set_session_id(ctx.session_id)
    |> Opcode.resume()
  end
end
