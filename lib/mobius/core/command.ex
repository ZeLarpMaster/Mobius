defmodule Mobius.Core.Command do
  @moduledoc false

  alias Mobius.Core.Command.ArgumentParser

  @enforce_keys [:name, :args, :handler]
  defstruct [:name, :args, :handler]

  @type t :: %__MODULE__{
          name: String.t(),
          args: keyword(ArgumentParser.arg_type()),
          handler: function()
        }

  @type handle_message_result ::
          {:ok, any()}
          | :not_a_command
          | {:too_few_args, t(), non_neg_integer()}
          | {:invalid_args, [{{:atom, ArgumentParser.arg_type()}, String.t()}]}

  @spec handle_message([t()], binary) :: handle_message_result()
  def handle_message(commands, message) do
    case parse_command(commands, message) do
      {:ok, command, arg_values} -> {:ok, execute(command, arg_values)}
      error -> error
    end
  end

  @spec command_handler_name(String.t()) :: atom()
  def command_handler_name(command_name) do
    :"__mobius_command_#{command_name}__"
  end

  @spec arg_names(t()) :: [String.t()]
  def arg_names(%__MODULE__{} = command) do
    command.args
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&Atom.to_string/1)
  end

  @spec arg_count(t()) :: non_neg_integer()
  def arg_count(%__MODULE__{} = command), do: length(command.args)

  defp parse_command(commands, message) do
    commands
    |> Enum.find(fn %__MODULE__{} = command -> String.starts_with?(message, command.name) end)
    |> case do
      nil ->
        :not_a_command

      %__MODULE__{} = command ->
        arg_values = split_arguments(message)

        with {:ok, values} <- validate(command, arg_values) do
          {:ok, command, values}
        end
    end
  end

  defp validate(%__MODULE__{} = command, values) do
    with :ok <- validate_arg_count(command, values),
         {:ok, values} <- parse_arg_values(command, values) do
      {:ok, values}
    end
  end

  defp execute(%__MODULE__{} = command, arg_values) do
    apply(command.handler, arg_values)
  end

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

  defp split_arguments(message) do
    message
    |> String.split()
    |> tl()
  end
end
