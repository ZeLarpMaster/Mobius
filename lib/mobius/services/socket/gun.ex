defmodule Mobius.Services.Socket.Gun do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Socket

  @behaviour Socket

  @type state :: %{
          url: String.t(),
          query: String.t(),
          zlib_stream: :zlib.zstream(),
          shard: ShardInfo.t(),
          gun_pid: pid | nil
        }

  @timeout_connect 10_000
  @timeout_gun_upgrade 10_000

  # Socket callbacks
  @impl Socket
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl Socket
  @spec send_message(GenServer.server(), term) :: :ok
  def send_message(socket, message) do
    GenServer.call(socket, {:send, message})
  end

  @impl Socket
  @spec close(GenServer.server()) :: :ok
  def close(socket) do
    GenServer.call(socket, :close)
  end

  # GenServer and :gun stuff
  @impl GenServer
  @spec init(keyword) :: {:ok, state(), {:continue, :ok}}
  def init(opts) do
    zlib_stream = :zlib.open()
    :zlib.inflateInit(zlib_stream)

    query =
      opts
      |> Keyword.fetch!(:query)
      |> add_impl_queries()
      |> encode_query()

    state = %{
      url: Keyword.fetch!(opts, :url),
      query: query,
      zlib_stream: zlib_stream,
      shard: Keyword.fetch!(opts, :shard),
      gun_pid: nil
    }

    # TODO: Trap exit so we can run Socket.notify_down/2 on shutdown?
    # TODO: Figure out what happens during this process' downtime

    {:ok, state, {:continue, :ok}}
  end

  @impl GenServer
  @spec handle_continue(:ok, state()) :: {:noreply, state()}
  def handle_continue(:ok, state) do
    {:ok, worker} = :gun.open(String.to_charlist(state.url), 443, %{protocols: [:http]})
    {:ok, :http} = :gun.await_up(worker, @timeout_connect)
    await_gun_upgrade(worker, state.query)

    {:noreply, %{state | gun_pid: worker}}
  end

  @impl GenServer
  def handle_call({:send, payload}, _from, state) do
    payload
    |> :erlang.term_to_binary()
    |> send_msg(state.gun_pid)

    {:reply, :ok, state}
  end

  def handle_call(:close, _from, state) do
    :ok = :gun.ws_send(state.gun_pid, :close)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:gun_ws, _worker, _stream, {:binary, frame}}, state) do
    message =
      state.zlib_stream
      |> :zlib.inflate(frame)
      |> :erlang.iolist_to_binary()
      |> :erlang.binary_to_term()

    Socket.notify_payload(state.shard, message)
    {:noreply, state}
  end

  def handle_info({:gun_ws, _worker, _stream, {:close, close_num, reason}}, state) do
    Socket.notify_closed(state.shard, close_num, reason)
    {:noreply, state}
  end

  def handle_info({:gun_down, _worker, _protocol, reason, _killed, _unprocessed}, state) do
    Socket.notify_down(state.shard, reason)
    {:noreply, state}
  end

  def handle_info({:gun_up, worker, _protocol}, state) do
    await_gun_upgrade(worker, state.query)
    Socket.notify_up(state.shard)
    :ok = :zlib.inflateReset(state.zlib_stream)
    {:noreply, state}
  end

  defp add_impl_queries(query) do
    query
    |> Map.put("encoding", "etf")
    |> Map.put("compress", "zlib-stream")
  end

  defp encode_query(query), do: "/?" <> URI.encode_query(query)

  # Byte size limit specified here: https://discord.com/developers/docs/topics/gateway#sending-payloads
  defp send_msg(msg, pid) when byte_size(msg) < 4096, do: :gun.ws_send(pid, {:binary, msg})
  defp send_msg(_msg, _pid), do: Logger.warn("Dropped a ws message longer than 4096 bytes!")

  defp await_gun_upgrade(worker, query) do
    stream = :gun.ws_upgrade(worker, query)

    receive do
      {:gun_upgrade, ^worker, ^stream, [<<"websocket">>], _headers} -> :ok
      {:gun_error, ^worker, ^stream, reason} -> exit({:ws_upgrade_error, reason})
    after
      @timeout_gun_upgrade ->
        Logger.error("Failed to upgrade WebSocket connection after #{@timeout_gun_upgrade} ms")
        exit(:timeout)
    end
  end
end
