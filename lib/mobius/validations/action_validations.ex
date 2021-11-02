defmodule Mobius.Validations.ActionValidations do
  @moduledoc """
  Validation utilities for actions

  ## Validator types

  ### :any

  Any value.

  ### :string

  Any string.

  ### {:string, keyword()}

  A string with options. The supported options are:
  - min: The minimum length of the string. Defaults to 0.
  - max: The maximum length of the string. Required.

  ### :integer

  Any integer.

  ### {:integer, keyword()}

  An integer with options. The supported options are:
  - min: The minimum value of the integer. Required.
  - max: The maximum value of the integer. Required.

  ### :snowflake

  Any snowflake.

  ### {module(), atom()}

  A custom validator. The first element must be a module name and the second one
  a one-arity function in that module. The function will receive the option
  value as its only argument.

  ### :emoji

  An emoji. Must be a `Mobius.Models.Emoji` struct.

  ## Constraints

  Constraints are similar to validator in that they verify that some conditions
  are met. The main difference between the two is that while validators operate
  on a single parameter at a time, constraints can operate on multiple
  parameters at a time.

  Following is the list of available constraints.

  ### {:at_least_one_of, [atom()]}

  Verifies that at least one of the specified parameter was provided to the
  action.
  """

  @type validator_type ::
          :string
          | {:string, keyword()}
          | :integer
          | {:integer, keyword()}
          | :snowflake
          | {module(), atom()}
          | :emoji
          | :any
  @type validator :: (any() -> :ok | {:error, String.t()})

  @type constraint :: {:at_least_one_of, [atom()]}

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
      val when is_integer(val) ->
        :ok

      val ->
        {:error, get_error_message.(val)}
    end
  end

  @spec emoji_validator :: validator()
  defp emoji_validator do
    fn
      %Mobius.Models.Emoji{} -> :ok
      val -> {:error, "be an emoji, got #{inspect(val)}"}
    end
  end

  def validate_constraints(params, constraints) do
    errors =
      Enum.reduce(constraints, [], fn {:at_least_one_of, options}, errors ->
        valid? =
          options
          |> Enum.map(fn option -> params[option] end)
          |> Enum.any?(fn val -> val != nil end)

        if valid? do
          errors
        else
          expected_options =
            options
            |> Enum.join(", ")

          ["Expected at least one of #{expected_options} but all were missing or nil." | errors]
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end

  @spec validate_args(Access.t(), [{atom(), validator()}]) :: :ok | {:error, [String.t()]}
  def validate_args(params, validators) do
    errors =
      Enum.reduce(validators, [], fn {param_name, validator}, errors ->
        val = params[param_name]

        if val != nil do
          case validator.(val) do
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
  def get_validator({module, function}), do: fn val -> apply(module, function, [val]) end
  def get_validator(:emoji), do: emoji_validator()
  def get_validator(:any), do: fn _ -> :ok end

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
    min = Keyword.get(opts, :min, 0)
    max = Keyword.fetch!(opts, :max)

    string_length_validator(min, max)
  end
end
