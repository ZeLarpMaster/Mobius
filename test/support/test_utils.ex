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

  Works identically for maps

  ## Examples

      iex> my_struct = %MyStruct{field: "value"}
      iex> assert_field(my_struct, :field, "value") == my_struct
      true

      iex> my_map = %{field: "value"}
      iex> assert_field(my_map, :field, "value") == my_map
      true
  """
  @spec assert_field(arg, atom, any) :: arg when arg: struct | map
  def assert_field(struct, field, expected_value) do
    assert Map.fetch!(struct, field) == expected_value
    struct
  end

  @doc """
  Asserts the a list of errors contains the expected error

  ## Examples

      iex> errors = ["error 1", "error 2"]
      iex> assert_has_error(errors, "error 1")
      true

      iex> errors = []
      iex> assert_has_error(errors, "error 1")
      false
  """
  @spec assert_has_error(String.t() | [String.t()], String.t()) :: boolean()
  def assert_has_error(error, expected_error)
      when is_binary(error) and is_binary(expected_error) do
    assert_has_error([error], expected_error)
  end

  def assert_has_error(errors, expected_error)
      when is_list(errors) and is_binary(expected_error) do
    assert Enum.any?(errors, fn error -> error =~ expected_error end),
           "Error message not found. Expected #{inspect(expected_error)}, received #{inspect(errors)}."
  end
end
