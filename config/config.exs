import Config

config :logger, :console, metadata: [:shard]

import_config("#{Mix.env()}.exs")
