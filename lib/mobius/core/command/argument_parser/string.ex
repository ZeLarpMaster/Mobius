defmodule Mobius.Core.Command.ArgumentParser.String do
  @moduledoc false

  @behaviour Mobius.Core.Command.ArgumentParser

  @impl true
  def parse(value), do: value
end
