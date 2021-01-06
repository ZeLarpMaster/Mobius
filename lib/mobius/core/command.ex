defmodule Mobius.Core.Command do
  @moduledoc false

  alias Mobius.Command.ArgumentParser

  @enforce_keys [:name, :args, :handler]
  defstruct [:name, :args, :handler]

  @type t :: %__MODULE__{
          name: String.t(),
          args: keyword(ArgumentParser.arg_type()),
          handler: function()
        }

  @spec command_handler_name(String.t()) :: atom()
  def command_handler_name(command_name) do
    :"mobius_command_#{command_name}"
  end

  @spec get_command_arg_names(keyword(atom())) :: [atom()]
  def get_command_arg_names(args) do
    Enum.map(args, &elem(&1, 0))
  end

  @spec parse_command([t()], String.t()) ::
          :not_a_command
          | {:ok, t(), [String.t()]}
          | {:too_few_args, t(), non_neg_integer()}
          | {:invalid_args, [{Validator.arg_type(), String.t()}]}
  def parse_command(commands, message) do
    case Enum.find(commands, fn %__MODULE__{} = command ->
           String.starts_with?(message, command.name)
         end) do
      nil ->
        :not_a_command

      %__MODULE__{} = command ->
        arg_values =
          message
          |> String.split()
          |> tl()

        with {:ok, values} <- validate(command, arg_values) do
          {:ok, command, values}
        end
    end
  end

  @spec validate(t(), [String.t()]) ::
          {:ok, [any()]} | {:too_few_args, t(), non_neg_integer()} | {:invalid_args, [String.t()]}
  defp validate(%__MODULE__{} = command, values) do
    with :ok <- validate_arg_count(command, values),
         {:ok, values} <- parse_arg_values(command, values) do
      {:ok, values}
    end
  end

  @spec execute(t(), [String.t()]) :: any
  def execute(%__MODULE__{} = command, arg_values) do
    apply(command.handler, arg_values)
  end

  @spec arg_names(t()) :: [String.t()]
  def arg_names(%__MODULE__{} = command) do
    command.args
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&Atom.to_string/1)
  end

  @spec arg_count(t()) :: non_neg_integer()
  def arg_count(%__MODULE__{} = command), do: length(command.args)

  defp validate_arg_count(%__MODULE__{} = command, values) do
    expected_count = arg_count(command)
    actual_count = length(values)

    if actual_count < expected_count do
      {:too_few_args, command, actual_count}
    else
      :ok
    end
  end

  defp parse_arg_values(%__MODULE__{} = command, values) do
    {errors, valids} =
      command.args
      |> Enum.zip(values)
      |> Enum.map(fn {{arg_name, arg_type}, value} ->
        {{arg_name, arg_type}, value, ArgumentParser.parse(arg_type, value)}
      end)
      |> Enum.split_with(fn {_, _, parse_result} -> parse_result == :error end)

    if errors != [] do
      {:invalid_args, Enum.map(errors, fn {arg, value, _} -> {arg, value} end)}
    else
      {:ok, Enum.map(valids, fn {_, _, val} -> val end)}
    end
  end
end
