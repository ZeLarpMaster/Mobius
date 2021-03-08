defmodule Mobius.Cogs.PingPong do
  @moduledoc false

  use Mobius.Cog

  import Mobius.Actions.Message

  command "ping", context do
    send_message(%{content: "Pong!"}, context["channel_id"])
  end
end
