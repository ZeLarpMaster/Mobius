defmodule Mobius.Command.ArgumentParser.Integer do
  @behaviour Mobius.Command.ArgumentParser

  @impl true
  def parse(value) do
    case Integer.parse(value) do
      :error -> :error
      {int, _} -> int
    end
  end
end
