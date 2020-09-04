defmodule Mobius.Services.Shard do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.SocketCodes
  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Heartbeat
  alias Mobius.Services.Socket

  @typep state :: %{
           seq: integer,
           session_id: String.t() | nil,
           token: String.t(),
           info: ShardInfo.t()
         }

  @typep payload :: %{
           op: integer,
           d: any,
           t: atom | nil,
           s: integer | nil
         }

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
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    %ShardInfo{} = shard_info = Keyword.fetch!(opts, :shard_info)

    state = %{
      seq: 0,
      session_id: nil,
      token: Keyword.fetch!(opts, :token),
      info: shard_info
    }

    # TODO: Link process to the other services
    # TODO: Figure out what to do when the other services die

    {:ok, state}
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
    # TODO: Side effects
    state
  end

  defp process_payload(:heartbeat, _payload, state) do
    Heartbeat.request_heartbeat(state.info)
    state
  end

  defp process_payload(:heartbeat_ack, _payload, state) do
    Heartbeat.received_ack(state.info)
    state
  end

  defp process_payload(:hello, payload, state) do
    # TODO: Start the heartbeat service
    if state.session_id == nil do
      # TODO: Make sure we can identify (only 1 identify per 5 seconds)
      # TODO: Send identify opcode
    else
      Logger.debug("Attempting to resume the session")
      # TODO: Send resume opcode
      # TODO: Set resuming flag?
    end

    state
  end

  defp process_payload(:invalid_session, %{d: false}, state) do
    # d: false -> don't resume
    Logger.debug("Invalid session. Server says don't resume")
    # TODO: If we were previously resuming, sleep randomly between 1 and 5 seconds
    Socket.close(state.info)
    %{state | session_id: nil}
  end

  defp process_payload(:invalid_session, %{d: true}, state) do
    # d: true -> Attempt to resume
    Logger.debug("Invalid session. Server says try to resume")
    # Close socket, when it comes back up we'll receive :hello and attempt to resume
    Socket.close(state.info)
    state
  end

  defp process_payload(:reconnect, _payload, state) do
    Logger.debug("Server asked for a reconnection")
    Socket.close(state.info)
    state
  end

  defp process_payload(type, payload, state) do
    Logger.warn("Unknown gateway event: #{inspect(type)} with payload: #{inspect(payload)}")
    state
  end

  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Shard, shard}}
  defp reply(state), do: {:reply, :ok, state}
end
