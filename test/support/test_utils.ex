defmodule Mobius.TestUtils do
  @moduledoc false

  import ExUnit.Assertions

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

  @doc """
  Asserts that two lists contain exactly the same items, regardless of order

  ## Examples

      iex> assert_list_unordered([1, 2, 3], [3, 2, 1])
      true

      iex> assert_list_unordered([1, 2, 3], [1, 2])
      false
  """
  @spec assert_list_unordered([any], [any]) :: any
  def assert_list_unordered(actual, expectation) do
    assert Enum.sort(actual) == Enum.sort(expectation)
  end

  @doc """
  Asserts that a struct's field contains the expected value and returns the struct

  ## Examples

      iex> my_struct = %MyStruct{field: "value"}
      iex> check_field(my_struct, :field, "value") == my_struct
      true
  """
  @spec check_field(arg, atom, any) :: arg when arg: struct
  def check_field(struct, field, expected_value) do
    assert Map.fetch!(struct, field) == expected_value
    struct
  end
end
