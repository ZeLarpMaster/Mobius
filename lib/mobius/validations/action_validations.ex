defmodule Mobius.Validations.ActionValidations do
  @moduledoc false

  @type validator :: (map() -> :ok | {:error, String.t()})

  @spec string_length_validator(Map.key(), non_neg_integer(), non_neg_integer()) ::
          validator()
  def string_length_validator(key, min, max) do
    fn
      %{^key => value} when not is_binary(value) ->
        {:error, "Expected #{key} to be a string, got #{inspect(value)}"}

      %{^key => value} ->
        string_length = String.length(value)

        if string_length >= min and string_length <= max do
          :ok
        else
          {:error,
           "Expected #{key} to contain between #{min} and #{max} characters, got #{value} with #{string_length} characters"}
        end

      _ ->
        :ok
    end
  end

  @spec integer_range_validator(Map.key(), integer(), integer()) ::
          validator()
  def integer_range_validator(key, min, max) do
    fn
      %{^key => value} when not is_integer(value) ->
        {:error, "Expected #{key} to be an integer, got #{inspect(value)}"}

      %{^key => value} when value < min or value > max ->
        {:error, "Expected #{key} to be between #{min} and #{max}, got #{value}"}

      _ ->
        :ok
    end
  end

  @spec validate_params(map(), [validator()]) :: :ok | {:error, [String.t()]}
  def validate_params(params, validators) do
    errors =
      Enum.reduce(validators, [], fn validator, errors ->
        case validator.(params) do
          :ok -> errors
          {:error, error} -> [error | errors]
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end
end
