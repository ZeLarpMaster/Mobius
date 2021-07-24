defmodule Mobius.Validations.ActionValidations do
  @moduledoc false

  @type validator :: (map() -> :ok | {:error, String.t()})

  @spec string_length_validator(Map.key(), non_neg_integer(), non_neg_integer()) ::
          validator()
  def string_length_validator(key, min, max) do
    fn params ->
      with :ok <- string_validator(key).(params),
           :ok <- length_validator(key, min, max).(params) do
        :ok
      end
    end
  end

  @spec integer_range_validator(Map.key(), integer(), integer()) ::
          validator()
  def integer_range_validator(key, min, max) do
    fn params ->
      with :ok <- integer_validator(key).(params),
           :ok <- range_validator(key, min, max).(params) do
        :ok
      end
    end
  end

  @spec string_validator(Map.key()) :: validator()
  def string_validator(key) do
    fn
      %{^key => val} when is_binary(val) -> :ok
      %{^key => val} -> {:error, "Expected #{key} to be a string, got #{inspect(val)}"}
      _ -> :ok
    end
  end

  @spec integer_validator(Map.key()) :: validator()
  def integer_validator(key) do
    fn
      %{^key => val} when is_integer(val) -> :ok
      %{^key => val} -> {:error, "Expected #{key} to be an integer, got #{inspect(val)}"}
      _ -> :ok
    end
  end

  def snowkflake_validator(key) do
    get_error_message = fn val -> "Expected #{key} to be a snowflake, got #{inspect(val)}" end

    fn
      %{^key => val} when not is_binary(val) ->
        {:error, get_error_message.(val)}

      %{^key => val} ->
        if Integer.parse(val) == :error do
          {:error, get_error_message.(val)}
        else
          :ok
        end

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

  defp length_validator(key, min, max) do
    fn
      %{^key => val} ->
        len = String.length(val)

        if len < min or len > max do
          {:error,
           "Expected #{key} to contain between #{min} and #{max} characters, got #{val} with #{len} characters"}
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp range_validator(key, min, max) do
    fn
      %{^key => value} when value < min or value > max ->
        {:error, "Expected #{key} to be between #{min} and #{max}, got #{value}"}

      _ ->
        :ok
    end
  end
end
