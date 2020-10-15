defmodule Mobius.Validations.Validator do
  @moduledoc false

  @type error :: {:error, String.t()}
  @type errors :: list(error())
  @type out :: :ok | errors()

  @spec required(out(), map, atom, (any -> out())) :: out()
  def required(errors, fields, field_name, validator) do
    fields
    |> Map.has_key?(field_name)
    |> check_required_field(fields, errors, field_name, validator)
  end

  @spec optional(out(), map, atom, (any -> out())) :: out()
  def optional(errors, fields, field_name, validator) do
    if Map.has_key?(fields, field_name) do
      required(errors, fields, field_name, validator)
    else
      errors
    end
  end

  @spec check(boolean, error()) :: :ok | error()
  def check(true, _message), do: :ok
  def check(false, message), do: message

  defp check_required_field(true, fields, errors, field_name, f) do
    fields
    |> Map.fetch!(field_name)
    |> f.()
    |> check_field(errors, field_name)
  end

  defp check_required_field(_present, _fields, errors, field_name, _f) do
    errors ++ [{field_name, "is required"}]
  end

  defp check_field(:ok, _errors, _field_name), do: :ok
  defp check_field({:error, message}, errors, field_name), do: errors ++ [{field_name, message}]

  defp check_field({:errors, messages}, errors, field_name),
    do: errors ++ Enum.map(messages, &{field_name, &1})
end
