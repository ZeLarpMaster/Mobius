defmodule Mobius.Assertions do
  @moduledoc false

  @doc """
  Returns runtime of a function call in milliseconds

  ## Examples

      iex> function_time(Process.sleep(50)) in 45..55
      true
  """
  @spec function_time(any) :: Macro.output()
  defmacro function_time(function) do
    quote do
      fn -> unquote(function) end
      |> :timer.tc()
      |> elem(0)
      |> :erlang.convert_time_unit(:microsecond, :millisecond)
    end
  end
end
