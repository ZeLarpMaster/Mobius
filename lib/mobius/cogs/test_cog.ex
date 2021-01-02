defmodule Mobius.Cogs.TestCog do
  @moduledoc false

  use Mobius.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end

  command "test", word: :string, times: :integer do
    IO.puts("#{word}#{times}")
  end

  command("test2", do: IO.puts("test2"))
end
