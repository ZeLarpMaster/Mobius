defmodule Mobius.Validations.Utils do
  @moduledoc false

  @type error :: {:error, String.t()}
  @type errors :: {:errors, [String.t()]}
  @type input :: :ok | error() | errors()
  @type output :: :ok | errors()

  @spec errors_to_output(list) :: output()
  def errors_to_output([]), do: :ok
  def errors_to_output(errors), do: {:errors, errors}

  @spec required(list, map, atom, (any -> input())) :: list
  def required(errors, fields, field_name, validator) do
    fields
    |> Map.has_key?(field_name)
    |> check_required_field(fields, errors, field_name, validator)
  end

  @spec optional(list, map, atom, (any -> input())) :: list
  def optional(errors, fields, field_name, validator) do
    if Map.has_key?(fields, field_name) do
      required(errors, fields, field_name, validator)
    else
      errors
    end
  end

  @spec check_list([val], (val -> input())) :: list when val: any
  def check_list(list, validator) do
    list
    |> Stream.map(validator)
    |> Stream.filter(&(&1 != :ok))
    |> Enum.flat_map(fn
      {:error, error} -> [error]
      {:errors, errors} -> errors
    end)
  end

  @spec check(boolean, error()) :: input()
  def check(true, _message), do: :ok
  def check(false, message), do: message

  defp check_required_field(true, fields, errors, field_name, f) do
    fields
    |> Map.fetch!(field_name)
    |> f.()
    |> assert_field(errors, field_name)
  end

  defp check_required_field(_present, _fields, errors, field_name, _f) do
    [{field_name, "is required"} | errors]
  end

  defp assert_field(:ok, _errors, _field_name), do: :ok
  defp assert_field({:error, message}, errors, field_name), do: [{field_name, message} | errors]

  defp assert_field({:errors, messages}, errors, field_name),
    do: errors ++ Enum.map(messages, &{field_name, &1})
end
