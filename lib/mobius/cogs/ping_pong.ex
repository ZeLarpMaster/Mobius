defmodule Mobius.Cogs.PingPong do
  @moduledoc false

  use Mobius.Cog

  require Logger

  command "ping", do: Logger.info("pong")
end
