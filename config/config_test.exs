import Config

config :ex_unit,
  assert_receive_timeout: 50,
  refute_receive_timeout: 50

config :mobius,
  ratelimiter_impl: Mobius.Stubs.CommandsRatelimiter,
  socket_impl: Mobius.Stubs.Socket,
  tesla_adapter: Tesla.Mock
