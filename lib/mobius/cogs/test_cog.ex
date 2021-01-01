defmodule Mobius.Cogs.TestCog do
  use Mobius.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end

  command "test", %{"word" => word, "tmp" => tmp} do
    IO.puts(word)
    IO.puts(tmp)
  end
end
