defmodule Mobius.Shard.Gateway do
  @moduledoc false

  alias Mobius.{ErrorCodes, Utils}
  alias Mobius.Models.Intents

  alias Mobius.Shard.{
    GatewayState,
    Opcodes,
    EventProcessor,
    MemberRequest,
    Gatekeeper,
    Socket,
    Ratelimiter
  }

  require Logger

  use GenServer

  @gateway_querystring "/?encoding=etf&compress=zlib-stream&v=6"

  # Gateway's Client API
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @spec request_heartbeat(GenServer.server()) :: :ok
  def request_heartbeat(gateway) do
    :ok = Process.send(gateway, :heartbeat_request, [])
  end

  @spec get_heartbeat_ping(GenServer.server()) :: integer
  def get_heartbeat_ping(gateway) do
    GenServer.call(gateway, :get_ping)
  end

  @spec get_intents(GenServer.server()) :: Intents.intents()
  def get_intents(gateway) do
    GenServer.call(gateway, :get_intents)
  end

  @spec update_intents(GenServer.server(), Intents.intents()) :: :ok
  def update_intents(gateway, intents) do
    GenServer.call(gateway, {:update_intents, intents})
  end

  # TODO: Revisit once intents are implemented (there's additional limits)
  def request_guild_members(gateway, guild_ids, user_ids, presences?) do
    MemberRequest.request_with_ids(gateway, guild_ids, user_ids, presences?)
  end

  def request_guild_members(gateway, guild_ids, username_prefix, limit, presences?) do
    MemberRequest.request_with_prefix(gateway, guild_ids, username_prefix, limit, presences?)
  end

  def update_status(gateway, status) when is_map(status) do
    GenServer.call(gateway, {:update_status, status})
  end

  def update_voice_status(gateway, %{"guild_id" => guild_id} = status) when guild_id != nil do
    GenServer.call(gateway, {:update_voice_status, status})
  end

  # GenServer API
  @spec init(keyword) :: {:ok, GatewayState.t()}
  def init(opts) do
    gateway_url = Keyword.fetch!(opts, :gateway_url)
    shard_num = Keyword.fetch!(opts, :shard_num)
    Logger.metadata(shard: shard_num)

    socket_pid =
      start_socket_if_needed(Keyword.get(opts, :socket_pid),
        url: gateway_url,
        query: @gateway_querystring
      )

    state = %GatewayState{
      seq: nil,
      session_id: nil,
      gateway_url: gateway_url <> @gateway_querystring,
      resuming: false,
      ack_connection: false,
      gateway_pid: self(),
      socket_pid: socket_pid,
      gatekeeper: Keyword.fetch!(opts, :gatekeeper),
      ratelimiter: Keyword.fetch!(opts, :ratelimiter),
      pubsub: Keyword.fetch!(opts, :pubsub),
      member_request_pids: %{},
      bot_id: Keyword.fetch!(opts, :bot_id),
      token: Keyword.fetch!(opts, :token),
      intents: Keyword.fetch!(opts, :intents),
      shard_num: shard_num,
      shard_count: Keyword.fetch!(opts, :shard_count),
      heartbeat_timer: nil,
      heartbeat_interval: nil,
      heartbeat_ping: 0,
      last_heartbeat: nil,
      last_heartbeat_ack: heartbeat_time()
    }

    {:ok, state}
  end

  def handle_info({:socket_message, payload}, state) do
    ack_connection_if_needed(state)
    state = %GatewayState{state | ack_connection: false, seq: payload.s || state.seq}

    payload.op
    |> Opcodes.opcode_to_name()
    |> EventProcessor.process(payload, state)
    |> case do
      {new_state, :close} ->
        Socket.close(state.socket_pid)
        {:noreply, new_state}

      {new_state, ws_message} ->
        send_message(state, ws_message)
        {:noreply, new_state}

      new_state ->
        {:noreply, new_state}
    end
  end

  # Called first when the server closes the socket
  def handle_info({:socket_closed, close_num, reason}, state) do
    {close_reason, what_can_do} = ErrorCodes.translate_gateway_error(close_num)
    Logger.warn("Socket closed (#{close_num}: #{close_reason}) #{reason}")
    if close_num == 4014, do: Intents.warn_privileged_intents(state.intents)
    state = stop_heartbeat(state)

    case what_can_do do
      :resume -> {:noreply, state}
      :dont_resume -> {:noreply, %GatewayState{state | session_id: nil}}
      :dont_reconnect -> {:stop, :gateway_error, state}
    end
  end

  # Is called after {:socket_closed, _, _} and after we call Socket.close/1
  def handle_info({:socket_down, reason}, state) do
    Logger.warn("Socket is down with reason #{inspect(reason)}")
    {:noreply, stop_heartbeat(state)}
  end

  def handle_info(:socket_up, state) do
    Logger.warn("Socket reconnected")
    {:noreply, %GatewayState{state | last_heartbeat_ack: heartbeat_time()}}
  end

  # Gateway callbacks
  def handle_info(:heartbeat_request, %GatewayState{last_heartbeat_ack: nil} = state) do
    Logger.warn("Didn't receive a heartbeat ack in time")
    state = stop_heartbeat(state)

    # Close the connection
    Socket.close(state.socket_pid)
    {:noreply, state}
  end

  def handle_info(:heartbeat_request, %GatewayState{} = state) do
    send_message(state, Opcodes.heartbeat(state))

    timer = Process.send_after(state.gateway_pid, :heartbeat_request, state.heartbeat_interval)

    {:noreply,
     %GatewayState{
       state
       | heartbeat_timer: timer,
         last_heartbeat_ack: nil,
         last_heartbeat: heartbeat_time()
     }}
  end

  def handle_call({:request_complete, nonce}, _from, %GatewayState{} = state) do
    {:reply, :ok, remove_task_nonce(state, nonce)}
  end

  def handle_call({:member_request, task_pid, payload}, _from, %GatewayState{} = state) do
    case check_global_ratelimit(state) do
      :ratelimited ->
        {:reply, {:error, :ratelimited}, state}

      :ok ->
        nonce = Utils.random_string(32)
        payload = Map.put(payload, "nonce", nonce)
        state = store_task_nonce(state, nonce, task_pid)
        Logger.debug("Asking for members with nonce #{inspect(nonce)}")
        send_message(state, Opcodes.request_guild_members(payload))
        {:reply, nonce, state}
    end
  end

  def handle_call(:get_ping, _from, %GatewayState{heartbeat_ping: ping} = state) do
    {:reply, ping, state}
  end

  def handle_call(:get_intents, _from, %GatewayState{intents: intents} = state) do
    {:reply, intents, state}
  end

  def handle_call({:update_intents, intents}, _from, %GatewayState{} = state) do
    Socket.close(state.socket_pid)
    {:reply, :ok, %GatewayState{state | session_id: nil, intents: intents}}
  end

  def handle_call({:update_status, status}, _from, %GatewayState{} = state) do
    # Check status ratelimit first to not empty the global ratelimit while being ratelimited for statuses
    cond do
      check_status_ratelimit(state) == :ratelimited ->
        {:reply, {:error, :ratelimited}, state}

      check_global_ratelimit(state) == :ratelimited ->
        {:reply, {:error, :ratelimited}, state}

      :ok ->
        send_message(state, Opcodes.update_status(status))
        {:reply, :ok, state}
    end
  end

  def handle_call({:update_voice_status, status}, _from, %GatewayState{} = state) do
    case check_global_ratelimit(state) do
      :ratelimited ->
        {:reply, {:error, :ratelimited}, state}

      :ok ->
        send_message(state, Opcodes.update_voice_status(status))
        {:reply, :ok, state}
    end
  end

  # Utility functions
  @spec heartbeat_time :: integer
  def heartbeat_time, do: System.monotonic_time(:millisecond)

  defp send_message(%GatewayState{socket_pid: pid}, message) do
    :ok = Socket.send_message(pid, message)
  end

  defp check_global_ratelimit(%GatewayState{} = state) do
    # The limit is 120, but we're reserving 5 commands per minute for keeping the bot alive
    check_ratelimit(state, "global", 60_000, 115)
  end

  defp check_status_ratelimit(%GatewayState{} = state) do
    # Found by testing a lot, this limit is undocumented on the official website
    # This was also "confirmed" by another user on the unofficial Discord API server
    check_ratelimit(state, "update_status", 60_000, 5)
  end

  defp check_ratelimit(%GatewayState{} = state, suffix, window_ms, max_commands) do
    bucket_name = "gateway:#{state.shard_num}:#{suffix}"
    Ratelimiter.request_access(state.ratelimiter, {bucket_name, window_ms, max_commands})
  end

  defp stop_heartbeat(%GatewayState{heartbeat_timer: nil} = state) do
    state
  end

  defp stop_heartbeat(%GatewayState{heartbeat_timer: timer} = state) do
    :ok = Process.cancel_timer(timer, info: false)
    %GatewayState{state | heartbeat_timer: nil}
  end

  defp store_task_nonce(%GatewayState{} = state, nonce, task_pid) do
    Map.update!(state, :member_request_pids, &Map.put(&1, nonce, task_pid))
  end

  defp remove_task_nonce(%GatewayState{} = state, nonce) do
    Map.update!(state, :member_request_pids, &Map.delete(&1, nonce))
  end

  defp start_socket_if_needed(nil, arg) do
    {:ok, pid} = Socket.start_link(arg)
    pid
  end

  defp start_socket_if_needed(socket_pid, _arg) do
    socket_pid
  end

  defp ack_connection_if_needed(%GatewayState{ack_connection: true} = state) do
    Gatekeeper.ack_identified(state.gatekeeper)
  end

  defp ack_connection_if_needed(%GatewayState{}) do
    :ok
  end
end
