defmodule Mobius.Shard.MemberRequestTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Utils
  alias Mobius.Shard.{MemberRequest, Socket, Opcodes, Gatekeeper}

  @moduletag gatekeeper_impl: Gatekeeper.Observing

  setup :create_proxy_socket
  setup :create_gatekeeper
  setup :create_pubsub
  setup :create_stub_ratelimiter
  setup :create_gateway

  describe "request_with_ids/4 contract" do
    test "raises when asking for more than 100 user ids" do
      user_ids = List.duplicate(random_snowflake(), 101)

      assert_raise RuntimeError, "Cannot ask for more than 100 members", fn ->
        MemberRequest.request_with_ids(nil, random_snowflake(), user_ids, false)
      end
    end

    test "calls the socket with the proper payload", %{gateway: gateway_pid} do
      guild_id = random_snowflake()
      user_id = random_snowflake()

      MemberRequest.request_with_ids(gateway_pid, guild_id, user_id, false)
      |> run_request_stream()

      expected_payload =
        %{
          "guild_id" => guild_id,
          "user_ids" => user_id,
          "presences" => false,
          "nonce" => Utils.random_string(nil)
        }
        |> Opcodes.request_guild_members()

      assert_receive {:socket_send, ^expected_payload}
      unblock_stream(gateway_pid)
    end
  end

  describe "request_with_prefix/5 contract" do
    test "raises when the limit is higher than 100" do
      assert_raise RuntimeError, "Cannot ask for more than 100 members", fn ->
        MemberRequest.request_with_prefix(nil, random_snowflake(), "", 101, false)
      end
    end

    test "raises when a prefix is provided with a limit of 0" do
      assert_raise RuntimeError, "Cannot request for all members when using a prefix", fn ->
        MemberRequest.request_with_prefix(nil, random_snowflake(), "a", 0, false)
      end
    end

    test "calls the socket with the proper payload", %{gateway: gateway_pid} do
      guild_id = random_snowflake()
      limit = :rand.uniform(100)

      MemberRequest.request_with_prefix(gateway_pid, guild_id, "a", limit, true)
      |> run_request_stream()

      expected_payload =
        %{
          "guild_id" => guild_id,
          "query" => "a",
          "limit" => limit,
          "presences" => true,
          "nonce" => Utils.random_string(nil)
        }
        |> Opcodes.request_guild_members()

      assert_receive {:socket_send, ^expected_payload}
      unblock_stream(gateway_pid)
    end
  end

  test "stops at the last chunk", %{gateway: gateway_pid} do
    guild_id = random_snowflake()
    user_id = random_snowflake()

    chunk = %{
      guild_id: guild_id,
      chunk_count: 2,
      nonce: Utils.random_string(nil),
      members: []
    }

    MemberRequest.request_with_ids(gateway_pid, guild_id, user_id, false)
    |> run_request_stream()

    # Socket was sent the request; the gateway is ready to get chunks
    assert_receive {:socket_send, _}

    chunk
    |> Map.put(:chunk_index, 0)
    |> send_chunk(gateway_pid)

    refute_receive {:stream_done, _}

    chunk
    |> Map.put(:chunk_index, 1)
    |> send_chunk(gateway_pid)

    assert_receive {:stream_done, _}
  end

  test "raises when it times out", %{gateway: gateway_pid} do
    guild_id = random_snowflake()
    user_id = random_snowflake()

    assert_raise Mobius.TimeoutError, fn ->
      MemberRequest.request_with_ids(gateway_pid, guild_id, user_id, false)
      |> Enum.to_list()
    end
  end

  test "injects the guild_id in members", %{gateway: gateway_pid} do
    guild_id = random_snowflake()
    user_id = random_snowflake()

    MemberRequest.request_with_ids(gateway_pid, guild_id, user_id, false)
    |> run_request_stream()

    # Socket was sent the request; the gateway is ready to get chunks
    assert_receive {:socket_send, _}

    %{
      guild_id: guild_id,
      chunk_index: 0,
      chunk_count: 1,
      nonce: Utils.random_string(nil),
      members: [%{user: %{username: "Alice"}}]
    }
    |> send_chunk(gateway_pid)

    assert_receive {:stream_done, list}

    assert list == [%{user: %{username: "Alice"}, guild_id: guild_id}]
  end

  test "chunks are sent even if they're received before the stream is ran", ctx do
    guild_id = random_snowflake()
    user_id = random_snowflake()

    stream =
      MemberRequest.request_with_ids(ctx.gateway, guild_id, user_id, false)
      |> Stream.map(fn data -> data.user.username end)

    assert_receive {:socket_send, _}

    %{
      guild_id: guild_id,
      chunk_index: 0,
      chunk_count: 1,
      nonce: Utils.random_string(nil),
      members: [%{user: %{username: "Alice"}}]
    }
    |> send_chunk(ctx.gateway)

    run_request_stream(stream)
    assert_receive {:stream_done, list}

    assert list == ["Alice"]
  end

  test "orders the chunks", %{gateway: gateway_pid} do
    guild_id = random_snowflake()
    user_id = random_snowflake()

    MemberRequest.request_with_ids(gateway_pid, guild_id, user_id, false)
    |> Stream.map(fn %{user: %{username: name}} -> name end)
    |> run_request_stream()

    # Socket was sent the request; the gateway is ready to get chunks
    assert_receive {:socket_send, _}

    %{
      guild_id: guild_id,
      chunk_index: 1,
      chunk_count: 2,
      nonce: Utils.random_string(nil),
      members: [%{user: %{username: "Bob"}}]
    }
    |> send_chunk(gateway_pid)

    refute_receive {:stream_done, _}

    %{
      guild_id: guild_id,
      chunk_index: 0,
      chunk_count: 2,
      nonce: Utils.random_string(nil),
      members: [%{user: %{username: "Alice"}}]
    }
    |> send_chunk(gateway_pid)

    assert_receive {:stream_done, list}

    assert list == ["Alice", "Bob"]
  end

  defp unblock_stream(gateway_pid) do
    %{
      guild_id: nil,
      chunk_index: 0,
      chunk_count: 1,
      nonce: Utils.random_string(nil),
      members: []
    }
    |> send_chunk(gateway_pid)
  end

  defp send_chunk(chunk, gateway_pid) do
    payload = %{d: chunk, op: Opcodes.name_to_opcode(:dispatch), s: 1, t: :GUILD_MEMBERS_CHUNK}
    Socket.notify_message(gateway_pid, payload)
  end

  defp run_request_stream(stream) do
    pid = self()

    spawn_link(fn ->
      list = Enum.to_list(stream)
      send(pid, {:stream_done, list})
    end)
  end
end
