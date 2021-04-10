defmodule Mobius.Core.Command do
  @moduledoc false

  alias Mobius.Core.Command.ArgumentParser
  alias Mobius.Models.Message

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
          | {:invalid_args, [{{atom(), ArgumentParser.arg_type()}, String.t()}]}

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

  @spec execute_command([t()], String.t(), Message.t()) :: handle_message_result()
  def execute_command(commands, prefix, %Message{content: content} = message) do
    arg_values = split_arguments(content)

    Enum.reduce_while(commands, :not_a_command, fn %__MODULE__{} = command, acc ->
      new =
        cond do
          not String.starts_with?(content, prefix <> command.name) -> :not_a_command
          arg_count(command) != length(arg_values) -> {:too_few_args, command, length(arg_values)}
          true -> try_command(command, arg_values, message)
        end

      decide_by_priority(acc, new)
    end)
  end

  defp decide_by_priority(old, new) do
    # Overwrite the accumulator depending on a priority list:
    # :ok (which halts the reduce) > :invalid_args > :too_few_args > :not_a_command
    # All the :cont are to let other clauses have their chance
    # However if one of the clauses has the right amount of args, but wrong types, that's the
    #   error we want to return ultimately if no other clause matches those arguments
    # Same logic applies for :too_few_args, if one clause is the right command with the wrong
    #   amount of args, but no other clause matches the command, that's the error we want
    # Finally, if none of the commands matches, we return :not_a_command
    case {old, new} do
      {{:ok, _} = value, _} -> {:halt, value}
      {_, {:ok, _} = value} -> {:halt, value}
      {{:invalid_args, _} = value, _} -> {:cont, value}
      {_, {:invalid_args, _} = value} -> {:cont, value}
      {{:too_few_args, _, _} = value, _} -> {:cont, value}
      {_, {:too_few_args, _, _} = value} -> {:cont, value}
      {:not_a_command, _} -> {:cont, :not_a_command}
      {_, :not_a_command} -> {:cont, :not_a_command}
    end
  end

  defp try_command(command, arg_values, %Message{} = message) do
    with {:ok, values} <- parse_arg_values(command, arg_values) do
      {:ok, apply(command.handler, [message | values])}
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
      {:ok, Enum.map(valids, fn {{_name, type}, _, val} -> {type, val} end)}
    end
  end

  defp split_arguments(message) do
    message
    |> String.split()
    |> tl()
  end
end
