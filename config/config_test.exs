import Config

config :mobius,
  ratelimiter_impl: Mobius.Stubs.CommandsRatelimiter,
  connection_ratelimiter_impl: Mobius.Stubs.ConnectionRatelimiter,
  socket_impl: Mobius.Stubs.Socket,
  tesla_adapter: Tesla.Mock
