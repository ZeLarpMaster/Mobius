defmodule Mobius.Cogs.PingPong do
  use Mobius.Cog

  require Logger

  command "ping", do: Logger.info("pong")
end
