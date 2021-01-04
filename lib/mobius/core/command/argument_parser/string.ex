defmodule Mobius.Command.ArgumentParser.String do
  @behaviour Mobius.Command.ArgumentParser

  @impl true
  def parse(value), do: value
end
