defmodule Mobius.Shard.EventProcessor do
  @moduledoc false

  alias Mobius.PubSub
  alias Mobius.Shard.{Gateway, Opcodes, GatewayState, Gatekeeper}

  require Logger

  @spec process(atom, map, GatewayState.t()) ::
          GatewayState.t() | {GatewayState.t(), binary} | {GatewayState.t(), :close}
  def process(:dispatch, payload, state) do
    Logger.debug("Dispatching #{inspect(payload.t)}")

    Task.start_link(fn ->
      PubSub.broadcast(state.pubsub, bot_events_topic(state.bot_id), payload.t, payload.d)
    end)

    case payload.t do
      :READY -> %GatewayState{state | session_id: payload.d.session_id}
      :RESUMED -> %GatewayState{state | resuming: false}
      :GUILD_MEMBERS_CHUNK -> handle_chunk(state, payload.d)
      _ -> state
    end
  end

  def process(:heartbeat, _payload, state) do
    Logger.debug("Server asked for a heartbeat")
    state = %GatewayState{state | last_heartbeat: Gateway.heartbeat_time()}
    {state, Opcodes.heartbeat(state)}
  end

  def process(:heartbeat_ack, _payload, state) do
    now = Gateway.heartbeat_time()

    ping =
      if state.last_heartbeat != nil do
        now - state.last_heartbeat
      else
        Logger.warn("Received a heartbeat ACK without sending a heartbeat since the last ACK")
        state.heartbeat_ping
      end

    %GatewayState{
      state
      | last_heartbeat_ack: now,
        heartbeat_ping: ping,
        last_heartbeat: nil
    }
  end

  def process(:hello, payload, state) do
    interval = payload.d.heartbeat_interval
    state = %GatewayState{state | heartbeat_interval: interval}

    Gateway.request_heartbeat(state.gateway_pid)

    if state.session_id == nil do
      # We didn't have a session so we're probably identifying for the first time
      # Wait until we're allowed to send an identify (it's limited to 1 per X seconds)
      # Note that this operation blocks the gateway process; which is what we want
      Gatekeeper.wait_until_can_identify(state.gatekeeper)
      {%GatewayState{state | ack_connection: true}, Opcodes.identify(state)}
    else
      Logger.debug("Attempting to resume the session")

      # We have a session so we're probably resuming
      {%GatewayState{state | resuming: true}, Opcodes.resume(state)}
    end
  end

  def process(:invalid_session, %{d: false}, state) do
    # d: false -> we shouldn't resume
    Logger.debug("Invalid session. Server says don't resume.")

    if state.resuming do
      # "It's also possible that your client cannot reconnect in time to resume,
      #   in which case the client will receive a Opcode 9 Invalid Session and
      #   is expected to wait a random amount of time — between 1 and 5 seconds —
      #   then send a fresh Opcode 2 Identify"
      # Source: https://discord.com/developers/docs/topics/gateway#resuming
      resuming_sleep()
    end

    # Remove the session_id so we assume it's a fresh session when we'll receive the :hello
    {%GatewayState{state | session_id: nil, resuming: false}, :close}
  end

  def process(:invalid_session, %{d: true}, state) do
    # d: true -> we can attempt to resume
    Logger.debug("Invalid session. Server says don't resume.")
    # We close the socket and when it comes back up, we'll receive a :hello and attempt to resume
    {%GatewayState{state | resuming: false}, :close}
  end

  def process(:reconnect, _payload, state) do
    Logger.debug("Server asked for a reconnection")
    # Disconnect and resume when we reconnect
    {state, :close}
  end

  def process(event, payload, state) do
    Logger.warn("Unknown gateway event: #{inspect(event)} with payload: #{inspect(payload)}")

    state
  end

  @spec handle_chunk(GatewayState.t(), map) :: GatewayState.t()
  def handle_chunk(%GatewayState{} = state, %{nonce: nonce} = payload) when nonce != nil do
    task_pid = Map.get(state.member_request_pids, nonce, nil)

    if task_pid != nil do
      send(task_pid, {:chunk, payload})
    else
      Logger.warn("GUILD_MEMBERS_CHUNK with an unknown nonce (#{inspect(nonce)})")
    end

    state
  end

  def handle_chunk(%GatewayState{} = state, _payload), do: state

  @spec bot_events_topic(String.t()) :: String.t()
  def bot_events_topic(suffix), do: "bot_events " <> suffix

  if Application.compile_env(:mobius, :skip_resuming_sleep, false) do
    defp resuming_sleep, do: Process.sleep(250)
  else
    defp resuming_sleep, do: Process.sleep(:rand.uniform(5) * 1000)
  end
end
