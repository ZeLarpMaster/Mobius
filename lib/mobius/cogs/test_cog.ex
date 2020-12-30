defmodule Mobius.Cogs.TestCog do
  use Mobius.Services.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end
end
