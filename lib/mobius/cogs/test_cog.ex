defmodule Mobius.Cogs.TestCog do
  @moduledoc false

  use Mobius.Cog

  listen :message_delete do
    IO.puts("message deleted")
  end

  command "test", word: :string, times: :integer do
    [word]
    |> Stream.cycle()
    |> Enum.take(times)
    |> Enum.join(", ")
    |> IO.puts()
  end

  command "test2", do: IO.puts("test2")
end
