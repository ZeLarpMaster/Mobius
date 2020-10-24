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

  def stub_socket(_context) do
    Stubs.Socket.set_owner(@shard)
  end

  def handshake_shard(_context) do
    send_hello()

    msg = Opcode.identify(@shard, System.fetch_env!("MOBIUS_BOT_TOKEN"))
    assert_receive {:socket_msg, ^msg}, 100

    session_id = random_hex(16)
    data = %{d: %{session_id: session_id}, t: :READY, s: 0, op: Opcode.name_to_opcode(:dispatch)}
    Socket.notify_payload(data, @shard)

    [session_id: session_id]
  end

  def create_token(_context) do
    [token: random_hex(8)]
  end

  def create_rest_client(context) do
    [client: Client.new(token: context.token)]
  end

  # Utility functions
  def send_hello(interval \\ 45_000) do
    data = %{
      d: %{heartbeat_interval: interval},
      op: Opcode.name_to_opcode(:hello),
      t: nil,
      s: nil
    }

    Socket.notify_payload(data, @shard)
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
