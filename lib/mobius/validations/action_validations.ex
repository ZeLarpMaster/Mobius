defmodule Mobius.Validations.ActionValidations do
  @moduledoc false

  @type validator_type ::
          :string | :integer | {:integer, keyword()} | :string | {:string, keyword()} | :snowflake
  @type validator :: (any() -> :ok | {:error, String.t()})

  @spec string_length_validator(non_neg_integer(), non_neg_integer()) ::
          validator()
  def string_length_validator(min, max) do
    fn value ->
      with :ok <- string_validator().(value),
           :ok <- length_validator(min, max).(value) do
        :ok
      end
    end
  end

  @spec integer_range_validator(integer(), integer()) ::
          validator()
  def integer_range_validator(min, max) do
    fn value ->
      with :ok <- integer_validator().(value),
           :ok <- range_validator(min, max).(value) do
        :ok
      end
    end
  end

  @spec string_validator :: validator()
  def string_validator do
    fn
      val when is_binary(val) -> :ok
      val -> {:error, "be a string, got #{inspect(val)}"}
    end
  end

  @spec integer_validator :: validator()
  def integer_validator do
    fn
      val when is_integer(val) -> :ok
      val -> {:error, "be an integer, got #{inspect(val)}"}
    end
  end

  @spec snowflake_validator :: validator()
  def snowflake_validator do
    get_error_message = fn val -> "be a snowflake, got #{inspect(val)}" end

    fn
      val when not is_binary(val) ->
        {:error, get_error_message.(val)}

      val ->
        if Integer.parse(val) == :error do
          {:error, get_error_message.(val)}
        else
          :ok
        end
    end
  end

  @spec validate_params(map(), [{atom(), validator()}]) :: :ok | {:error, [String.t()]}
  def validate_params(params, validators) do
    errors =
      Enum.reduce(validators, [], fn {param_name, validator}, errors ->
        if Map.has_key?(params, param_name) do
          case validator.(params[param_name]) do
            :ok -> errors
            {:error, error} -> ["Expected #{param_name} to #{error}" | errors]
          end
        else
          errors
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end

  @spec get_validator(validator_type()) :: validator()
  def get_validator(:snowflake), do: snowflake_validator()
  def get_validator(:integer), do: integer_validator()
  def get_validator({:integer, opts}), do: get_integer_range_validator(opts)
  def get_validator(:string), do: string_validator()
  def get_validator({:string, opts}), do: get_string_length_validator(opts)

  defp length_validator(min, max) do
    fn
      val ->
        len = String.length(val)

        if len < min or len > max do
          {:error,
           "contain between #{min} and #{max} characters, got #{val} with #{len} characters"}
        else
          :ok
        end
    end
  end

  defp range_validator(min, max) do
    fn
      value when value < min or value > max ->
        {:error, "be between #{min} and #{max}, got #{value}"}

      _ ->
        :ok
    end
  end

  defp get_integer_range_validator(opts) do
    min = Keyword.fetch!(opts, :min)
    max = Keyword.fetch!(opts, :max)

    integer_range_validator(min, max)
  end

  defp get_string_length_validator(opts) do
    min = Keyword.fetch!(opts, :min)
    max = Keyword.fetch!(opts, :max)

    string_length_validator(min, max)
  end
end
