import Config

config :mobius,
  member_request_timeout_ms: 500,
  time_between_connections_ms: 500,
  skip_resuming_sleep: true,
  tesla_adapter: Tesla.Mock,
  gatekeeper_impl: Mobius.Shard.Gatekeeper.Observing,
  ratelimiter_impl: Mobius.Shard.Ratelimiter.Stub,
  socket_impl: Mobius.Shard.Socket.Proxy

config :mobius, :test_config, random_string: "a random string"

config :ex_unit, assert_receive_timeout: 250
