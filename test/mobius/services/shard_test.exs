defmodule Mobius.Services.ShardTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Core.Gateway
  alias Mobius.Core.Intents
  alias Mobius.Core.Opcode

  # Currently hardcoded in Mobius.Application
  @intents Intents.all_intents()

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :stub_connection_ratelimiter

  describe "shard" do
    @describetag intents: @intents
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

      msg = Opcode.identify(ctx.shard, ctx.token, @intents)
      assert_receive {:socket_msg, ^msg}
    end

    test "exits the shard if socket closes with unrecoverable code", ctx do
      # Shard will completely disconnect when closed with code 4013 (Invalid intent(s))
      # See Mobius.Core.SocketCodes for the list of codes
      close_socket_from_server(4013, "Invalid intent(s)")

      pid = GenServer.whereis({:via, Registry, {Mobius.Registry.Shard, ctx.shard}})
      assert pid == nil
    end

    test "warns about intents if socket closes with 4014" do
      # 4014 is the code for disallowed intents and is sent went trying to connect
      # with intents which weren't enabled for the bot
      intents = "guild_members, guild_presences"

      assert capture_log(fn ->
               close_socket_from_server(4014, "Disallowed intent(s)")
             end) =~ "You used the intents #{intents}, but at least one of them isn't enabled"
    end

    test "sleeps before reconnecting after a failed resume", ctx do
      # Make the bot attempt a resume
      send_payload(op: :invalid_session, data: true)
      send_hello()
      resume = make_resume_payload(ctx, 1)
      assert_receive {:socket_msg, ^resume}

      # Make the bot fail to resume
      sleep_time = Application.fetch_env!(:mobius, :resuming_sleep_time_ms)
      # Because `notify_payload` is synchronous, `send_payload` will be tanking the sleep time
      # Therefore we are asserting the time it takes to execute to check the sleep time
      # We also use a tolerance of 25ms to avoid false positives caused by intense cpu usage
      [op: :invalid_session, data: false]
      |> send_payload()
      |> function_time()
      |> assert_in_delta(sleep_time, 25)
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

      msg = Opcode.identify(ctx.shard, ctx.token, @intents)
      assert_receive {:socket_msg, ^msg}
    end

    test "closes socket if discord requests reconnection" do
      send_payload(op: :reconnect)

      assert_receive :socket_close
    end

    test "waits until can connect when identifying" do
      # The setup does a handshake which makes the shard request the connection ratelimiter
      # Hence the message should already be there
      assert_received {:connection_request, _}
    end
  end

  describe "acks the connection on" do
    setup do
      send_hello()
      assert_receive_heartbeat()
      assert_receive_identify()
      assert_received {:connection_request, pid}
      [pid: pid]
    end

    test "invalid session which can resume", %{pid: pid} do
      send_payload(op: :invalid_session, data: true)

      assert_receive {:connection_ack, ^pid}
    end

    test "invalid session which can't resume", %{pid: pid} do
      send_payload(op: :invalid_session, data: false)

      assert_receive {:connection_ack, ^pid}
    end

    test "ready", %{pid: pid} do
      send_payload(op: :dispatch, seq: 1, type: "READY", data: %{"session_id" => random_hex(16)})

      assert_receive {:connection_ack, ^pid}
    end
  end

  defp make_resume_payload(ctx, seq) do
    ctx.token
    |> Gateway.new()
    |> Gateway.update_seq(seq)
    |> Gateway.set_session_id(ctx.session_id)
    |> Opcode.resume()
  end
end
