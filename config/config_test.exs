import Config

config :mobius,
  socket_impl: Mobius.Stubs.Socket,
  tesla_adapter: Tesla.Mock
