defmodule Mobius.Shard.GatewayState do
  @moduledoc false

  defstruct [
    # Discord state
    :seq,
    :session_id,
    :gateway_url,
    :resuming,
    :ack_connection,
    # Pids
    :gateway_pid,
    :socket_pid,
    :gatekeeper,
    :ratelimiter,
    :pubsub,
    :member_request_pids,
    # Settings
    :bot_id,
    :token,
    :intents,
    # Shards
    :shard_num,
    :shard_count,
    # Heartbeat
    :heartbeat_timer,
    :heartbeat_interval,
    :heartbeat_ping,
    :last_heartbeat,
    :last_heartbeat_ack
  ]

  @typedoc "The sequence number of the latest event"
  @type sequence_number :: integer | nil

  @typedoc "The ID of the current session"
  @type session_id :: String.t() | nil

  @typedoc "The full URL used to connect to the gateway"
  @type gateway_url :: String.t()

  @typedoc "true when the gateway tried to resume until it resumes or fails to resume"
  @type resuming :: boolean

  @typedoc "true when the gateway should ack to the connection manager as soon as possible"
  @type ack_connection :: boolean

  @typedoc "The PID of the gateway's process"
  @type gateway_pid :: pid

  @typedoc "The PID of the socket"
  @type socket_pid :: pid

  @typedoc "The name or pid of the gatekeeper"
  @type gatekeeper :: atom | pid

  @typedoc "The way to communicate with the ratelimit server"
  @type ratelimiter :: GenServer.server()

  @typedoc "The name of the `Mobius.PubSub` for this gateway"
  @type pubsub :: atom

  @typedoc "The mapping between member request nonces and their task's pid"
  @type member_request_pids :: %{required(String.t()) => pid}

  @typedoc "A uniquely identifying string for the bot owning this gateway"
  @type bot_id :: String.t()

  @typedoc "The token used by Discord to identify the bot; This token is expected to be kept private"
  @type token :: String.t()

  @typedoc "This shard's number"
  @type shard_number :: integer

  @typedoc "The total number of shards"
  @type shard_count :: integer

  @typedoc "The reference to the heartbeat's timer"
  @type heartbeat_timer :: integer | nil

  @typedoc "The amount of time between each heartbeat"
  @type heartbeat_interval :: integer | nil

  @typedoc "The difference between the latest heartbeat ACK and its heartbeat"
  @type heartbeat_ping :: integer

  @typedoc "The time of the last heartbeat sent"
  @type last_heartbeat :: integer | nil

  @typedoc "The time of the last heartbeat ack received"
  @type last_heartbeat_ack :: integer | nil

  @type t :: %__MODULE__{
          seq: sequence_number,
          session_id: session_id,
          gateway_url: gateway_url,
          resuming: resuming,
          ack_connection: ack_connection,
          gateway_pid: gateway_pid,
          socket_pid: socket_pid,
          gatekeeper: gatekeeper,
          ratelimiter: ratelimiter,
          pubsub: pubsub,
          member_request_pids: member_request_pids,
          bot_id: bot_id,
          token: token,
          intents: Mobius.Models.Intents.intents(),
          shard_num: shard_number,
          shard_count: shard_count,
          heartbeat_timer: heartbeat_timer,
          heartbeat_interval: heartbeat_interval,
          heartbeat_ping: heartbeat_ping,
          last_heartbeat: last_heartbeat,
          last_heartbeat_ack: last_heartbeat_ack
        }
end
