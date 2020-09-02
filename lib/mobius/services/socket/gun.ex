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
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl Socket
  def send_message(socket, message) do
    GenServer.call(socket, {:send, message})
  end

  @impl Socket
  def close(socket) do
    GenServer.call(socket, :close)
  end

  # GenServer and :gun stuff
  @impl GenServer
  def init(opts) do
    zlib_stream = :zlib.open()
    :zlib.inflateInit(zlib_stream)

    state = %{
      url: Keyword.fetch!(opts, :url),
      query: Keyword.fetch!(opts, :query),
      zlib_stream: zlib_stream,
      shard: Keyword.fetch!(opts, :shard)
    }

    {:ok, state, {:continue, :ok}}
  end

  @impl GenServer
  def handle_continue(:ok, state) do
    {:ok, worker} = :gun.open(String.to_charlist(state.url), 443, %{protocols: [:http]})
    {:ok, :http} = :gun.await_up(worker, @timeout_connect)
    await_gun_upgrade(worker, state.query)

    {:noreply, %{state | gun_pid: worker}}
  end

  @impl GenServer
  def handle_cast({:send, payload}, state) do
    message = :erlang.term_to_binary(payload)

    if byte_size(message) < 4096 do
      :ok = :gun.ws_send(state.gun_pid, {:binary, message})
    else
      Logger.warn("Attempted to send a ws message longer than 4096 bytes! Dropped it instead.")
    end

    {:noreply, state}
  end

  def handle_cast(:close, state) do
    :ok = :gun.ws_send(state.gun_pid, :close)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:gun_ws, _worker, _stream, {:binary, frame}}, state) do
    message =
      state.zlib_stream
      |> :zlib.inflate(frame)
      |> :erlang.iolist_to_binary()
      |> :erlang.binary_to_term()

    Socket.notify_message(state.parent_pid, message)
    {:noreply, state}
  end

  def handle_info({:gun_ws, _worker, _stream, {:close, close_num, reason}}, state) do
    Socket.notify_closed(state.parent_pid, close_num, reason)
    {:noreply, state}
  end

  def handle_info({:gun_down, _worker, _protocol, reason, _killed, _unprocessed}, state) do
    Socket.notify_down(state.parent_pid, reason)
    {:noreply, state}
  end

  def handle_info({:gun_up, worker, _protocol}, state) do
    await_gun_upgrade(worker, state.query)
    Socket.notify_up(state.parent_pid)
    :ok = :zlib.inflateReset(state.zlib_stream)
    {:noreply, state}
  end

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
