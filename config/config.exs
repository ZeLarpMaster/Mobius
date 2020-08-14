import Config

config :logger, :console, metadata: [:shard]

config :mobius,
  member_request_timeout_ms: 10_000,
  tesla_adapter: Tesla.Adapter.Hackney,
  gatekeeper_impl: Mobius.Shard.Gatekeeper.Timed,
  ratelimiter_impl: Mobius.Shard.Ratelimiter.SelfRefill,
  socket_impl: Mobius.Shard.Socket.Gun

import_config("#{Mix.env()}.exs")
