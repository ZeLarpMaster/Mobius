defmodule Mobius.Cogs.TestCog do
  use Mobius.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end

  command "test" do
    IO.puts("test command")
  end
end
