import Config

config :ex_unit,
  assert_receive_timeout: 75,
  refute_receive_timeout: 75

config :mobius,
  default_global_prefix: "sudo ",
  resuming_sleep_time_ms: 75,
  ratelimiter_impl: Mobius.Stubs.CommandsRatelimiter,
  connection_ratelimiter_impl: Mobius.Stubs.ConnectionRatelimiter,
  socket_impl: Mobius.Stubs.Socket,
  tesla_adapter: Tesla.Mock
