defmodule Mobius.Command.ArgumentParser do
  @moduledoc false

  alias Mobius.Command.ArgumentParser

  @callback parse(String.t()) :: any() | :error

  @type arg_type :: :string | :integer

  @parsers %{
    string: ArgumentParser.String,
    integer: ArgumentParser.Integer
  }

  @spec parse(arg_type(), String.t()) :: any() | :error
  def parse(type, value) do
    @parsers
    |> Map.get(type)
    |> apply(:parse, [value])
  end
end
