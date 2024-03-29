defmodule Mobius.Fixtures do
  @moduledoc false

  import ExUnit.Assertions

  alias Mobius.Core.Intents
  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Models.Message
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot
  alias Mobius.Services.Socket
  alias Mobius.Stubs

  @shard ShardInfo.new(number: 0, count: 1)

  def token, do: System.get_env("MOBIUS_BOT_TOKEN", "default_token")

  def reset_services(_context) do
    Mobius.Application.reset_services()
  end

  def get_shard(_context) do
    [shard: @shard]
  end

  def stub_socket(_context) do
    Stubs.Socket.set_owner(@shard)
  end

  def stub_ratelimiter(_context) do
    Stubs.CommandsRatelimiter.set_owner()
  end

  def stub_connection_ratelimiter(_context) do
    Stubs.ConnectionRatelimiter.set_owner()
  end

  def handshake_shard(context) do
    send_hello()
    assert_receive_heartbeat()
    assert_receive_identify(context[:intents] || Intents.all_intents())
    session_id = random_hex(16)

    data = %{
      d: %{"session_id" => session_id},
      t: "READY",
      s: 1,
      op: Opcode.name_to_opcode(:dispatch)
    }

    Socket.notify_payload(data, @shard)

    # Yield to give the shard time to handle the message. Not a very safe way to
    # do this, but since there's barely anything going on during tests it works
    # well enough.
    Process.sleep(5)
    assert Bot.ready?()

    [session_id: session_id, token: token()]
  end

  def create_rest_client(_context) do
    token = random_hex(8)
    [token: token, client: Client.new(token: token, max_retries: 0)]
  end

  # Utility functions
  @spec mock_gateway_bot(integer, integer) :: any
  def mock_gateway_bot(remaining \\ 1000, reset_after \\ 0) do
    app_info = %{
      "shards" => 1,
      "url" => "wss://gateway.discord.gg",
      "session_start_limit" => %{"remaining" => remaining, "reset_after" => reset_after}
    }

    url = Client.base_url() <> "/gateway/bot"
    Tesla.Mock.mock_global(fn %{url: ^url, method: :get} -> Mobius.Fixtures.json(app_info) end)
  end

  def send_hello(interval \\ 45_000) do
    send_payload(op: :hello, data: %{"heartbeat_interval" => interval})
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

  def assert_receive_heartbeat(seq \\ 0) do
    msg = Opcode.heartbeat(seq)
    assert_receive {:socket_msg, ^msg}, 50
  end

  def assert_receive_identify(intents \\ Intents.all_intents()) do
    msg = Opcode.identify(@shard, token(), intents)
    assert_receive {:socket_msg, ^msg}, 50
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

  def random_n_chars(n, chars) do
    1..n
    |> Enum.map(fn _ -> Enum.random(String.codepoints(chars)) end)
    |> Enum.join()
  end

  def random_hex(len), do: random_n_chars(len, "0123456789abcdef")

  def random_snowflake, do: :rand.uniform(100_000_000_000)

  def random_discriminator, do: random_n_chars(4, "0123456789")

  def random_text(len), do: random_n_chars(len, "abcdefghijklmnopqrstuvwxyz")

  def json(term, status_code \\ 200) do
    {status_code, [{"content-type", "application/json"}], Jason.encode!(term)}
  end

  def empty_response do
    {204, [], nil}
  end

  def send_command_payload(content) do
    prefix = Bot.get_global_prefix!()
    send_message_payload(prefix <> content)
  end

  def send_message_payload(content) do
    message = %{"content" => content}

    send_payload(
      op: :dispatch,
      type: "MESSAGE_CREATE",
      data: message
    )

    Message.parse(message)
  end
end
