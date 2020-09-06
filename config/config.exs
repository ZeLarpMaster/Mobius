import Config

config :logger, :console, metadata: [:shard]

import_config("config_#{Mix.env()}.exs")
