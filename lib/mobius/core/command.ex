defmodule Mobius.Core.Command do
  @moduledoc false

  alias Mobius.Core.Command.ArgumentParser
  alias Mobius.Models.Message

  @enforce_keys [:name, :args, :handler]
  defstruct [:name, :args, :handler, description: ""]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | false | nil,
          args: keyword(ArgumentParser.arg_type()),
          handler: function()
        }

  @type command_arities :: %{non_neg_integer() => [t()]}
  @type processed :: %{String.t() => command_arities()}

  @type handle_message_result ::
          {:ok, any()}
          | :not_a_command
          | {:too_few_args, [non_neg_integer()], non_neg_integer()}
          | {:invalid_args, [t]}

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

  @spec execute_command(processed(), String.t(), Message.t()) :: handle_message_result()
  def execute_command(commands, prefix, %Message{content: content} = message) do
    with {:ok, content} <- match_prefix(prefix, content),
         {:ok, name, arg_values} <- split_arguments(content),
         {:ok, groups} <- get_command(commands, name),
         {:ok, clauses} <- get_clauses(groups, length(arg_values)),
         {:ok, command, values} <- find_clause(clauses, arg_values) do
      {:ok, apply(command.handler, [message | values])}
    end
  end

  @spec preprocess_commands([t()]) :: processed()
  def preprocess_commands(commands) do
    commands
    |> Enum.reverse()
    |> Enum.group_by(fn %__MODULE__{name: name} -> name end)
    |> Map.new(fn {name, commands} -> {name, Enum.group_by(commands, &arg_count/1)} end)
  end

  defp get_command(commands, name) do
    case Map.fetch(commands, name) do
      :error -> :not_a_command
      {:ok, clause_groups} -> {:ok, clause_groups}
    end
  end

  defp get_clauses(clause_groups, arity) do
    case Map.fetch(clause_groups, arity) do
      :error -> {:too_few_args, Map.keys(clause_groups), arity}
      {:ok, clauses} -> {:ok, clauses}
    end
  end

  defp find_clause(clauses, arg_values) do
    Enum.find_value(clauses, {:invalid_args, clauses}, &parse_arg_values(&1, arg_values))
  end

  defp parse_arg_values(%__MODULE__{} = command, values) do
    {errors, valids} =
      command.args
      |> Enum.zip(values)
      |> Enum.map(fn {{arg_name, arg_type}, value} ->
        {{arg_name, arg_type}, value, ArgumentParser.parse(arg_type, value)}
      end)
      |> Enum.split_with(fn {_, _, parse_result} -> parse_result == :error end)

    if errors == [] do
      {:ok, command, Enum.map(valids, fn {{_name, type}, _, val} -> {type, val} end)}
    end
  end

  defp match_prefix(prefix, content) do
    if String.starts_with?(content, prefix) do
      {:ok, String.replace_prefix(content, prefix, "")}
    else
      :not_a_command
    end
  end

  defp split_arguments(content) do
    case String.split(content) do
      [] -> :not_a_command
      [name | args] -> {:ok, name, args}
    end
  end
end
