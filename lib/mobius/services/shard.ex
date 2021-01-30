defmodule Mobius.Services.Shard do
  @moduledoc false

  use GenServer

  alias Mobius.Core.Gateway
  alias Mobius.Core.Intents
  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo
  alias Mobius.Core.SocketCodes
  alias Mobius.Services.Bot
  alias Mobius.Services.ConnectionRatelimiter
  alias Mobius.Services.EventPipeline
  alias Mobius.Services.Heartbeat
  alias Mobius.Services.Socket

  require Logger

  @gateway_version "8"

  @typep state :: %{
           gateway: Gateway.t(),
           intents: Intents.t(),
           shard: ShardInfo.t()
         }

  @typep payload :: %{
           op: integer,
           d: any,
           t: String.t() | nil,
           s: integer | nil
         }

  @spec start_shard(ShardInfo.t(), keyword) :: DynamicSupervisor.on_start_child()
  def start_shard(shard, opts) do
    DynamicSupervisor.start_child(Mobius.Supervisor.Shard, {__MODULE__, {shard, opts}})
  end

  @spec child_spec({ShardInfo.t(), keyword}) :: Supervisor.child_spec()
  def child_spec({shard, opts}) do
    %{
      id: shard,
      start: {__MODULE__, :start_link, [shard, opts]},
      restart: :transient
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

  @spec notify_payload(payload(), ShardInfo.t()) :: :ok
  def notify_payload(payload, shard) do
    GenServer.call(via(shard), {:payload, payload})
  end

  @spec notify_closed(ShardInfo.t(), integer, String.t()) :: :ok
  def notify_closed(shard, close_num, reason) do
    GenServer.call(via(shard), {:socket_closed, close_num, reason})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    %ShardInfo{} = shard = Keyword.fetch!(opts, :shard)
    Logger.debug("Started shard on pid #{inspect(self())}")

    state = %{
      gateway: Gateway.new(Keyword.fetch!(opts, :token)),
      intents: Keyword.fetch!(opts, :intents),
      shard: shard
    }

    url = Keyword.fetch!(opts, :url)
    {:ok, pid} = Socket.start_socket(state.shard, url, %{"v" => @gateway_version})

    Logger.debug("Started socket on #{inspect(pid)}")

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
    if close_num == 4014, do: warn_privileged_intents(state.intents)

    case what_can_do do
      :resume -> {:reply, :ok, state}
      :dont_resume -> {:reply, :ok, reset_session(state)}
      :dont_reconnect -> {:stop, {:shutdown, :gateway_error}, :ok, state}
    end
  end

  def handle_call(:get_seq, _from, state) do
    {:reply, state.gateway.seq, state}
  end

  # Update the state and execute side effects depending on opcode
  defp process_payload(:dispatch, payload, state) do
    state
    |> update_seq(payload.s)
    |> update_state_by_event(payload)
    |> broadcast_event(payload)
  end

  defp process_payload(:heartbeat, _payload, state) do
    Heartbeat.request_heartbeat(state.shard, state.gateway.seq)
    state
  end

  defp process_payload(:heartbeat_ack, _payload, state) do
    Heartbeat.received_ack(state.shard)
    state
  end

  defp process_payload(:hello, payload, state) do
    interval = Map.fetch!(payload.d, "heartbeat_interval")
    {:ok, pid} = Heartbeat.start_heartbeat(state.shard, interval)
    Logger.debug("Started heartbeat on #{inspect(pid)}")

    if Gateway.has_session?(state.gateway) do
      Logger.debug("Attempting to resume the session")

      state.gateway
      |> Opcode.resume()
      |> Socket.send_message(state.shard)

      set_resuming(state, true)
    else
      # Send the identify when the ratelimiter allows it
      ConnectionRatelimiter.wait_until_can_connect(fn ->
        state.shard
        |> Opcode.identify(state.gateway.token, state.intents)
        |> Socket.send_message(state.shard)
      end)

      state
    end
  end

  defp process_payload(:invalid_session, %{d: false}, state) do
    # d: false -> don't resume
    Logger.debug("Invalid session. Server says don't resume")
    # Invalid session can happen after identifying, so we ack to let the next shard try to connect
    ConnectionRatelimiter.ack_connected()
    Socket.close(state.shard)

    if state.gateway.resuming do
      # "It's also possible that your client cannot reconnect in time to resume,
      #   in which case the client will receive a Opcode 9 Invalid Session and
      #   is expected to wait a random amount of time — between 1 and 5 seconds —
      #   then send a fresh Opcode 2 Identify"
      # Source: https://discord.com/developers/docs/topics/gateway#resuming
      resuming_sleep()
    end

    # We might've attempted to resume and failed, therefore we aren't resuming anymore
    reset_session(set_resuming(state, false))
  end

  defp process_payload(:invalid_session, %{d: true}, state) do
    # d: true -> Attempt to resume
    Logger.debug("Invalid session. Server says try to resume")
    # Invalid session can happen after identifying, so we ack to let the next shard try to connect
    ConnectionRatelimiter.ack_connected()
    # Close socket, when it comes back up we'll receive :hello and attempt to resume
    Socket.close(state.shard)
    # Invalid session can happen after a failed attempt to resume
    #   which means we aren't resuming anymore
    set_resuming(state, false)
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

  defp update_state_by_event(state, %{t: "READY", d: d}) do
    # READY only happens when identifying and is the first thing we receive after identifying
    # Therefore it's the perfect opportunity to ack that we have connected
    ConnectionRatelimiter.ack_connected()
    Bot.notify_ready(state.shard)
    set_session(state, Map.fetch!(d, "session_id"))
  end

  defp update_state_by_event(state, %{t: "RESUMED"}) do
    # RESUMED is sent after a successful resume which means we aren't resuming anymore
    set_resuming(state, false)
  end

  defp update_state_by_event(state, _payload), do: state

  defp broadcast_event(state, %{t: type}) when type in ["READY"], do: state

  defp broadcast_event(state, payload) do
    EventPipeline.notify_event(payload.t, payload.d)
    state
  end

  defp warn_privileged_intents(intents) do
    intents_string =
      intents
      |> Intents.filter_privileged_intents()
      |> Enum.map(&Atom.to_string/1)
      |> Enum.join(", ")

    Logger.warn("You used the intents #{intents_string}, but at least one of them isn't enabled")
  end

  defp resuming_sleep do
    # Make tests not take excessively long
    sleep_time_ms = Application.get_env(:mobius, :resuming_sleep_time_ms, :rand.uniform(5) * 1000)
    Process.sleep(sleep_time_ms)
  end

  defp update_seq(state, seq), do: update_in(state.gateway, &Gateway.update_seq(&1, seq))
  defp set_session(state, id), do: update_in(state.gateway, &Gateway.set_session_id(&1, id))
  defp reset_session(state), do: update_in(state.gateway, &Gateway.reset_session_id/1)
  defp set_resuming(state, value), do: update_in(state.gateway, &Gateway.set_resuming(&1, value))

  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Shard, shard}}
  defp reply(state), do: {:reply, :ok, state}
end
