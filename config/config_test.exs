import Config

config :mobius,
  ratelimiter_impl: Mobius.Stubs.CommandsRatelimiter,
  socket_impl: Mobius.Stubs.Socket,
  tesla_adapter: Tesla.Mock
