defmodule Mobius.Cogs.PingPong do
  @moduledoc "Defines the ping pong command"

  use Mobius.Cog

  @doc ~s(Replies with "Pong!")
  command "ping" do
    {:reply, %{content: "Pong!"}}
  end
end
