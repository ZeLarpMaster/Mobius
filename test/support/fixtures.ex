defmodule Mobius.Fixtures do
  @moduledoc false

  import ExUnit.Assertions

  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Rest.Client
  alias Mobius.Services.Socket
  alias Mobius.Stubs

  @shard ShardInfo.new(number: 0, count: 1)

  def reset_services(_context) do
    Mobius.Application.reset_services()
  end

  def get_shard(_context) do
    [shard: @shard]
  end

  def stub_socket(_context) do
    Stubs.Socket.set_owner(@shard)
  end

  def handshake_shard(_context) do
    send_hello()

    msg = Opcode.heartbeat(0)
    assert_receive {:socket_msg, ^msg}, 100

    token = System.fetch_env!("MOBIUS_BOT_TOKEN")
    msg = Opcode.identify(@shard, token)
    assert_receive {:socket_msg, ^msg}, 100

    session_id = random_hex(16)
    data = %{d: %{session_id: session_id}, t: :READY, s: 1, op: Opcode.name_to_opcode(:dispatch)}
    Socket.notify_payload(data, @shard)

    [session_id: session_id, token: token]
  end

  def create_token(_context) do
    [token: random_hex(8)]
  end

  def create_rest_client(context) do
    [client: Client.new(token: context.token)]
  end

  # Utility functions
  def send_hello(interval \\ 45_000) do
    send_payload(op: :hello, data: %{heartbeat_interval: interval})
  end

  def send_payload(opts) do
    data = %{
      op: Opcode.name_to_opcode(Keyword.fetch!(opts, :op)),
      d: Keyword.get(opts, :data),
      t: Keyword.get(opts, :type),
      s: Keyword.get(opts, :seq)
    }

    Socket.notify_payload(data, @shard)
  end

  @doc "Simulate the server closing the socket with an arbitrary code"
  def close_socket_from_server(close_num, reason) do
    # Closed is notified only when the server closes the connection
    Socket.notify_closed(@shard, close_num, reason)
    # Down is notified regardless of whether it was closed by the server or the client
    Socket.notify_down(@shard, reason)
    # Up is notified once it has reconnected by itself
    Socket.notify_up(@shard)
  end

  @chars String.codepoints("0123456789abcdef")
  def random_hex(len) do
    1..len
    |> Enum.map(fn _ -> Enum.random(@chars) end)
    |> Enum.join()
  end

  def json(term, status_code \\ 200) do
    {status_code, [{"content-type", "application/json"}], Jason.encode!(term)}
  end
end
