defmodule Mobius.Fixtures do
  @moduledoc false

  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot
  alias Mobius.Services.Socket
  alias Mobius.Stubs

  @shard ShardInfo.new(number: 0, count: 1)

  def stub_socket(_context) do
    @shard
    |> Socket.via()
    |> Stubs.Socket.set_owner()

    [socket: Socket.via(hd(Bot.list_shards()))]
  end

  def handshake_shard(_context) do
    data = %{d: %{heartbeat_interval: 45_000}, op: Opcode.name_to_opcode(:hello), t: nil, s: nil}
    Socket.notify_payload(data, @shard)

    @shard
    |> Socket.via()
    |> Stubs.Socket.has_message?(fn msg ->
      msg == Opcode.identify(@shard, System.fetch_env!("MOBIUS_BOT_TOKEN"))
    end)

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
