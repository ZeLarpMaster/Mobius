defmodule Mobius.Cogs.PingPong do
  @moduledoc "Defines the ping pong command"

  use Mobius.Cog

  import Mobius.Actions.Message

  @doc ~s(Replies with "Pong!")
  command "ping", context do
    send_message(%{content: "Pong!"}, context.channel_id)
  end
end
