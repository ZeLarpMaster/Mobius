defmodule Mobius.Core.Command.ArgumentParser.Integer do
  @moduledoc false

  @behaviour Mobius.Core.Command.ArgumentParser

  @impl true
  def parse(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> :error
    end
  end
end
