defmodule Mobius.Cogs.TestCog do
  @moduledoc false

  use Mobius.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end

  command "test", word1: :string, word2: :string do
    IO.puts("#{word1}#{word2}")
  end

  command("test2", do: IO.puts("test2"))
end
