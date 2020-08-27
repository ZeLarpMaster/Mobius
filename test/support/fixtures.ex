defmodule Mobius.Fixtures do
  @moduledoc false

  import ExUnit.Callbacks

  alias Mobius.ETSShelf
  alias Mobius.PubSub
  alias Mobius.Api.Client
  alias Mobius.Shard.Gateway
  alias Mobius.Shard.Ratelimiter

  def create_api_client(_context) do
    token = random_hex(8)
    pid = start_supervised!(Mobius.Api.Middleware.Ratelimit)
    [client: Client.new(token, pid), ratelimit_server: pid, token: token]
  end

  def create_proxy_socket(_context) do
    [socket: self()]
  end

  def create_gateway(context) do
    shard_num = random_id()
    token = random_hex(16)

    gateway_pid =
      start_supervised!(
        {Gateway,
         gateway_url: "",
         name: :"TestGateway #{shard_num}",
         bot_id: Integer.to_string(shard_num),
         token: token,
         shard_num: shard_num,
         shard_count: 1,
         ratelimiter: context.ratelimiter,
         socket_pid: context.socket,
         pubsub: context.pubsub,
         gatekeeper: context.gatekeeper}
      )

    [gateway: gateway_pid, shard_num: shard_num, token: token]
  end

  def create_gatekeeper(%{gatekeeper_impl: impl}) do
    {:ok, gatekeeper_pid} = impl.start_link([nil])
    on_exit(fn -> Process.exit(gatekeeper_pid, :shutdown) end)
    [gatekeeper: gatekeeper_pid]
  end

  def create_stub_ratelimiter(_context) do
    pid = start_supervised!({Ratelimiter.Stub, parent: self()})
    [ratelimiter: pid]
  end

  def create_pubsub(_context) do
    name = :"PubSubTest#{random_id()}"
    start_supervised!({PubSub, name: name})
    [pubsub: name]
  end

  def create_shelf(_context) do
    {:ok, server} = ETSShelf.start_link([])
    [shelf: server]
  end

  def create_pid(_context) do
    {:ok, pid} =
      Task.start(fn ->
        receive do
          _ -> :ok
        end
      end)

    on_exit(fn -> send(pid, :exit) end)

    [pid: pid]
  end

  @chars "0123456789abcdef" |> String.codepoints()
  def random_hex(len) do
    1..len
    |> Enum.map(fn _ -> Enum.random(@chars) end)
    |> Enum.join()
  end

  def random_snowflake do
    :rand.uniform(999_999_999_999_999_999)
  end

  defp random_id do
    :rand.uniform(10000)
  end

  def json(term, status_code \\ 200) do
    {status_code, [{"content-type", "application/json"}], Jason.encode!(term)}
  end
end
