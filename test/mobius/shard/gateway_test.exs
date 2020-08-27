defmodule Mobius.Shard.GatewayTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mobius.Fixtures

  alias Mobius.PubSub
  alias Mobius.Models.Intents
  alias Mobius.Shard.{Socket, Gatekeeper, Opcodes, EventProcessor, Gateway, Ratelimiter}

  @moduletag gatekeeper_impl: Gatekeeper.Observing

  setup :create_proxy_socket
  setup :create_gatekeeper
  setup :create_pubsub
  setup :create_stub_ratelimiter
  setup :create_gateway

  describe "gateway behaviour" do
    test "responds to hello with an identify", %{gateway: gateway, shard_num: shard, token: token} do
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      data = receive_from_gateway(:identify)
      assert data["token"] == token
      assert data["shard"] == [shard, 1]
      assert data["properties"]["$browser"] == "Mobius"
      assert data["properties"]["$device"] == "Mobius"
      assert Map.has_key?(data["properties"], "$os")
    end

    test "resumes if connection drops", %{gateway: gateway, token: token} do
      session_id = random_hex(16)
      seq = :rand.uniform(200)
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: session_id}, 0, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(gateway, :heartbeat_ack)
      send_opcode(gateway, :dispatch, %{}, seq, :TESTING)

      Socket.notify_down(gateway, "Testing")
      Socket.notify_up(gateway)

      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      data = receive_from_gateway(:resume)
      assert data["token"] == token
      assert data["seq"] == seq
      assert data["session_id"] == session_id
    end

    test "doesn't resume if close num says so", ctx do
      session_id = random_hex(16)
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(ctx.gateway, :dispatch, %{session_id: session_id}, 1, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)

      Socket.notify_closed(ctx.gateway, 4001, "Testing")
      Socket.notify_down(ctx.gateway, "Testing")

      Socket.notify_up(ctx.gateway)
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
    end

    test "shutdowns if close num says the situation can't be recovered", %{gateway: gateway} do
      session_id = random_hex(16)
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: session_id}, 1, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(gateway, :heartbeat_ack)

      ref = Process.monitor(gateway)
      Socket.notify_closed(gateway, 4004, "Testing")
      Socket.notify_down(gateway, "Testing")

      assert_receive {:DOWN, ^ref, :process, ^gateway, :gateway_error}
    end

    test "disconnects and reconnects if sent a :reconnect", %{gateway: gateway} do
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: random_hex(16)}, :rand.uniform(200), :READY)

      send_opcode(gateway, :reconnect)
      assert_receive :socket_close
    end

    test "sends heartbeat `heartbeat_interval`ms after the previous one", %{gateway: gateway} do
      seq = :rand.uniform(200)
      interval = :rand.uniform(50) + 100
      send_opcode(gateway, :hello, %{heartbeat_interval: interval})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: random_hex(16)}, seq, :READY)

      # The very first heartbeat will always be nil since we didn't receive any event yet
      assert nil == receive_from_gateway(:heartbeat)
      send_opcode(gateway, :heartbeat_ack)

      send_opcode(gateway, :heartbeat)
      assert seq == receive_from_gateway(:heartbeat)

      refute_receive {:socket_send, _}, interval - 25
      assert seq == receive_from_gateway(:heartbeat)
    end

    test "disconnects if it doesn't receive a heartbeat_ack in time", %{gateway: gateway} do
      interval = :rand.uniform(50) + 100
      send_opcode(gateway, :hello, %{heartbeat_interval: interval})
      receive_from_gateway(:heartbeat)

      # Expected at `interval`, we tolerate +- 50ms
      refute_receive :socket_close, interval - 50
      assert_receive :socket_close

      # Ensure no other heartbeat is sent after
      refute_receive_from_gateway(:heartbeat, interval + 100)
    end

    test "warns when it receives a ACK without sending a heartbeat", ctx do
      interval = :rand.uniform(50) + 100
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: interval})
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)

      log =
        capture_log(fn ->
          send_opcode(ctx.gateway, :heartbeat_ack)
          # Give the gateway time to process the opcode
          Gateway.get_heartbeat_ping(ctx.gateway)
        end)

      assert log =~ "heartbeat ACK without sending a heartbeat"
    end

    test "doesn't send another heartbeat after disconnecting", ctx do
      interval = :rand.uniform(50) + 100
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: interval})
      receive_from_gateway(:identify)
      send_opcode(ctx.gateway, :dispatch, %{session_id: random_hex(16)}, 1, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)

      # 4003 is an arbitrary error code where the gateway shouldn't attempt to reconnect
      Socket.notify_closed(ctx.gateway, 4003, "For testing")

      refute_receive_from_gateway(:heartbeat, interval + 100)
    end

    test "doesn't send another heartbeat after socket closes", ctx do
      interval = :rand.uniform(50) + 100
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: interval})
      receive_from_gateway(:identify)
      send_opcode(ctx.gateway, :dispatch, %{session_id: random_hex(16)}, 1, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)

      Socket.notify_down(ctx.gateway, "For testing")

      refute_receive_from_gateway(:heartbeat, interval + 100)
    end

    test "sleeps before identifying after a failed resume", %{gateway: gateway} do
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: random_hex(16)}, :rand.uniform(200), :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(gateway, :heartbeat_ack)

      # Make the gateway attempt to resume
      send_opcode(gateway, :invalid_session, true)
      assert_receive :socket_close
      close_gateway(gateway)
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:resume)

      # Fail the attempt of resuming
      send_opcode(gateway, :invalid_session, false)
      # Expected to sleep for 250ms, we tolerate +- 25ms
      refute_receive :socket_close, 225
      assert_receive :socket_close, 50
    end

    test "asks the gatekeeper before identifying", %{gateway: gateway} do
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      assert_receive {:identifying, ^gateway}
      assert_receive {:socket_send, _}
      receive_from_gateway(:heartbeat)
      refute_receive {:socket_send, _}

      # Check it tells the gatekeeper on the first opcode after identifying
      send_opcode(gateway, :dispatch, %{session_id: random_hex(16)}, 1, :READY)
      assert_receive {:identified, ^gateway}

      send_opcode(gateway, :dispatch, %{}, 2, :TESTING)
      refute_receive {:identified, _}
    end

    test "broadcasts :dispatch events", %{gateway: gateway, pubsub: pubsub, shard_num: shard_num} do
      session_id = random_hex(16)
      PubSub.subscribe(pubsub, EventProcessor.bot_events_topic(Integer.to_string(shard_num)))
      send_opcode(gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(gateway, :dispatch, %{session_id: session_id}, :rand.uniform(200), :READY)

      assert_receive {:READY, %{session_id: ^session_id}}
    end
  end

  describe "get_heartbeat_ping" do
    test "returns a ping close to the time between a heartbeat and a ack", ctx do
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(ctx.gateway, :dispatch, %{session_id: random_hex(16)}, 1, :READY)

      before_time = System.monotonic_time(:millisecond)
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)
      # Gives time to the gateway to receive and process the ack
      ping = Gateway.get_heartbeat_ping(ctx.gateway)
      after_time = System.monotonic_time(:millisecond)

      # 10 ms of tolerance
      assert ping <= after_time - before_time + 10
    end
  end

  describe "intents" do
    @tag intents: MapSet.new([:guilds])
    test "get_intents/1 returns the intents given when starting", ctx do
      assert ctx.intents == Gateway.get_intents(ctx.gateway)
    end

    test "update_intents/2 closes the socket and reidentifies with new intents", ctx do
      session_id = random_hex(16)
      intents = MapSet.new([:guilds, :guild_messages])
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: 100})
      receive_from_gateway(:identify)
      send_opcode(ctx.gateway, :dispatch, %{session_id: session_id}, 1, :READY)
      receive_from_gateway(:heartbeat)
      send_opcode(ctx.gateway, :heartbeat_ack)

      assert Intents.all_intents() == Gateway.get_intents(ctx.gateway)

      :ok = Gateway.update_intents(ctx.gateway, intents)
      assert_receive :socket_close
      # Gateway expects a down notification when the socket is closed
      Socket.notify_down(ctx.gateway, "Testing")

      # At any time after this, the gateway is expected to reply with the new intents
      assert intents == Gateway.get_intents(ctx.gateway)

      # Socket is brought back up
      Socket.notify_up(ctx.gateway)
      send_opcode(ctx.gateway, :hello, %{heartbeat_interval: 100})
      # Gateway reidentifies with the new intents even though we had a session
      data = receive_from_gateway(:identify)
      assert data["intents"] == Intents.intents_to_integer(intents)
    end
  end

  describe "update_status" do
    test "{:error, :ratelimited} if ratelimited", ctx do
      Ratelimiter.Stub.set_emptiness(ctx.ratelimiter, true)
      assert {:error, :ratelimited} == Gateway.update_status(ctx.gateway, %{})
    end

    test "returns :ok and sends payload", ctx do
      status = %{
        "status" => "idle",
        "afk" => true,
        "since" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
        "game" => %{
          "type" => 0,
          "name" => "tests!"
        }
      }

      assert :ok == Gateway.update_status(ctx.gateway, status)
      data = receive_from_gateway(:presence_update)
      assert data == status
    end
  end

  describe "update_voice_status" do
    test "{:error, :ratelimited} if ratelimited", ctx do
      Ratelimiter.Stub.set_emptiness(ctx.ratelimiter, true)

      assert {:error, :ratelimited} ==
               Gateway.update_voice_status(ctx.gateway, %{"guild_id" => random_snowflake()})
    end

    test "returns :ok and sends payload", ctx do
      status = %{
        "guild_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "self_deaf" => true,
        "self_mute" => true
      }

      assert :ok == Gateway.update_voice_status(ctx.gateway, status)
      data = receive_from_gateway(:voice_status_update)
      assert data == status
    end
  end

  describe "request_guild_members" do
    test "{:error, :ratelimited} if ratelimited", ctx do
      Ratelimiter.Stub.set_emptiness(ctx.ratelimiter, true)
      guild_id = random_snowflake()
      user_id = random_snowflake()

      assert {:error, :ratelimited} ==
               Gateway.request_guild_members(ctx.gateway, guild_id, user_id, false)
    end

    test "streams the members in correct order", ctx do
      guild_id = random_snowflake()
      user_id = random_snowflake()
      pid = self()

      stream =
        Gateway.request_guild_members(ctx.gateway, guild_id, user_id, false)
        |> Stream.map(fn data -> data.user.username end)

      spawn_link(fn ->
        list = Enum.to_list(stream)
        send(pid, {:stream_done, list})
      end)

      request = receive_from_gateway(:request_guild_members)

      chunk = %{
        guild_id: guild_id,
        chunk_index: 1,
        chunk_count: 2,
        nonce: request["nonce"],
        members: [%{user: %{username: "Bob"}}]
      }

      send_opcode(ctx.gateway, :dispatch, chunk, 1, :GUILD_MEMBERS_CHUNK)

      chunk = %{
        guild_id: guild_id,
        chunk_index: 0,
        chunk_count: 2,
        nonce: request["nonce"],
        members: [%{user: %{username: "Alice"}}]
      }

      send_opcode(ctx.gateway, :dispatch, chunk, 2, :GUILD_MEMBERS_CHUNK)

      assert_receive {:stream_done, list}
      assert list == ["Alice", "Bob"]

      # Test it doesn't recognize the same nonce after the chunks are done
      log =
        capture_log(fn ->
          send_opcode(ctx.gateway, :dispatch, chunk, 3, :GUILD_MEMBERS_CHUNK)
          # Make the Gateway do something to give it time to process the opcode ^
          Gateway.get_heartbeat_ping(ctx.gateway)
        end)

      assert log =~ "GUILD_MEMBERS_CHUNK with an unknown nonce"
    end
  end

  defp receive_from_gateway(name) do
    opcode = Opcodes.name_to_opcode(name)
    assert_receive {:socket_send, %{"op" => ^opcode, "d" => data}}
    data
  end

  defp refute_receive_from_gateway(name, timeout) do
    opcode = Opcodes.name_to_opcode(name)
    refute_receive {:socket_send, %{"op" => ^opcode}}, timeout
  end

  defp send_opcode(gateway, name, data \\ nil, seq \\ nil, type \\ nil) do
    %{
      d: data,
      s: seq,
      t: type,
      op: Opcodes.name_to_opcode(name)
    }
    |> send_term(gateway)
  end

  defp send_term(term, gateway) do
    Socket.notify_message(gateway, term)
  end

  defp close_gateway(gateway) do
    Socket.notify_down(gateway, "Testing")
  end
end
