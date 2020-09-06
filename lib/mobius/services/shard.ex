defmodule Mobius.Services.Shard do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.SocketCodes
  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Heartbeat
  alias Mobius.Services.Socket

  @gateway_version "6"

  @typep state :: %{
           seq: integer,
           session_id: String.t() | nil,
           token: String.t(),
           shard: ShardInfo.t()
         }

  @typep payload :: %{
           op: integer,
           d: any,
           t: atom | nil,
           s: integer | nil
         }

  @spec start_shard(ShardInfo.t(), String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_shard(shard, url, token) do
    DynamicSupervisor.start_child(
      Mobius.Supervisor.Shard,
      {__MODULE__, {shard, url: url, token: token}}
    )
  end

  @spec child_spec({ShardInfo.t(), keyword}) :: Supervisor.child_spec()
  def child_spec({shard, opts}) do
    %{
      id: shard,
      start: {__MODULE__, :start_link, [shard, opts]},
      restart: :permanent
    }
  end

  @spec start_link(ShardInfo.t(), keyword) :: GenServer.on_start()
  def start_link(shard, opts) do
    GenServer.start_link(__MODULE__, opts ++ [shard: shard], name: via(shard))
  end

  @spec get_sequence_number(ShardInfo.t()) :: integer
  def get_sequence_number(shard) do
    GenServer.call(via(shard), :get_seq)
  end

  @spec notify_payload(ShardInfo.t(), payload()) :: :ok
  def notify_payload(shard, payload) do
    GenServer.call(via(shard), {:payload, payload})
  end

  @spec notify_closed(ShardInfo.t(), integer, String.t()) :: :ok
  def notify_closed(shard, close_num, reason) do
    GenServer.call(via(shard), {:socket_closed, close_num, reason})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state(), {:continue, any}}
  def init(opts) do
    %ShardInfo{} = shard = Keyword.fetch!(opts, :shard)
    Logger.debug("Started shard on pid #{inspect(self())}")

    state = %{
      seq: 0,
      session_id: nil,
      token: Keyword.fetch!(opts, :token),
      shard: shard
    }

    {:ok, state, {:continue, {:start_socket, Keyword.fetch!(opts, :url)}}}
  end

  @impl GenServer
  @spec handle_continue({:start_socket, String.t()}, state()) :: {:noreply, state()}
  def handle_continue({:start_socket, url}, state) do
    {:ok, pid} = Socket.start_socket(state.shard, url, %{"v" => @gateway_version})
    Logger.debug("Started socket on pid #{inspect(pid)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:payload, payload}, _from, state) do
    payload.op
    |> Opcode.opcode_to_name()
    |> process_payload(payload, state)
    |> reply()
  end

  def handle_call({:socket_closed, close_num, reason}, _from, state) do
    {close_reason, what_can_do} = SocketCodes.translate_close_code(close_num)
    Logger.warn("Socket closed (#{close_num}: #{close_reason}) #{reason}")

    case what_can_do do
      :resume -> {:reply, :ok, state}
      :dont_resume -> {:reply, :ok, %{state | session_id: nil}}
      :dont_reconnect -> {:stop, :gateway_error, :ok, state}
    end
  end

  def handle_call(:get_seq, _from, state) do
    {:reply, state.seq, state}
  end

  # Update the state and execute side effects depending on opcode
  defp process_payload(:dispatch, payload, state) do
    Logger.debug("Dispatching #{inspect(payload.t)}")
    # TODO: Broadcast event
    update_state_by_event(payload, state)
  end

  defp process_payload(:heartbeat, _payload, state) do
    Heartbeat.request_heartbeat(state.shard, state.seq)
    state
  end

  defp process_payload(:heartbeat_ack, _payload, state) do
    Heartbeat.received_ack(state.shard)
    state
  end

  defp process_payload(:hello, payload, state) do
    interval = payload.d.heartbeat_interval
    {:ok, pid} = Heartbeat.start_heartbeat(state.shard, interval)
    Logger.debug("Started heartbeat on pid #{inspect(pid)}")

    if state.session_id == nil do
      # TODO: Make sure we can identify (only 1 identify per 5 seconds)
      Socket.send_message(state.shard, Opcode.identify(state.shard, state.token))
    else
      Logger.debug("Attempting to resume the session")
      Socket.send_message(state.shard, Opcode.resume(state.session_id, state.seq, state.token))
      # TODO: Set resuming flag? See :invalid_session for why
    end

    state
  end

  defp process_payload(:invalid_session, %{d: false}, state) do
    # d: false -> don't resume
    Logger.debug("Invalid session. Server says don't resume")
    # TODO: If we were previously resuming, sleep randomly between 1 and 5 seconds
    Socket.close(state.shard)
    %{state | session_id: nil}
  end

  defp process_payload(:invalid_session, %{d: true}, state) do
    # d: true -> Attempt to resume
    Logger.debug("Invalid session. Server says try to resume")
    # Close socket, when it comes back up we'll receive :hello and attempt to resume
    Socket.close(state.shard)
    state
  end

  defp process_payload(:reconnect, _payload, state) do
    Logger.debug("Server asked for a reconnection")
    Socket.close(state.shard)
    state
  end

  defp process_payload(type, payload, state) do
    Logger.warn("Unknown gateway event: #{inspect(type)} with payload: #{inspect(payload)}")
    state
  end

  defp update_state_by_event(%{t: :READY, d: d}, state), do: %{state | session_id: d.session_id}
  defp update_state_by_event(_payload, state), do: state

  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Shard, shard}}
  defp reply(state), do: {:reply, :ok, state}
end
