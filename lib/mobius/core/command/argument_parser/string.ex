defmodule Mobius.Command.ArgumentParser.String do
  @moduledoc false

  @behaviour Mobius.Command.ArgumentParser

  @impl true
  def parse(value), do: value
end
