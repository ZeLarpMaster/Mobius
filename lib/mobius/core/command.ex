defmodule Mobius.Core.Command do
  @moduledoc false

  @type name :: String.t()
  @type handler :: atom()
  @type arg_names :: [atom()]
  @type arg_types :: [String.t()]
  @type arg_values :: [String.t()]

  @spec command_handler_name(String.t()) :: atom()
  def command_handler_name(command_name) do
    :"mobius_command_#{command_name}"
  end

  @spec get_command_arg_names(keyword(atom())) :: [atom()]
  def get_command_arg_names(args) do
    args
    |> Enum.map(&elem(&1, 0))
  end

  @spec validate_command([{name(), handler(), arg_names(), arg_types()}], String.t()) ::
          :not_a_command
          | {:ok, {name(), handler(), arg_names(), arg_values()}}
          | {:too_few_args, name(), non_neg_integer(), non_neg_integer()}
  def validate_command(commands, message) do
    case Enum.find(commands, fn {name, _handler, _arg_names, _arg_types} ->
           String.starts_with?(message, name)
         end) do
      nil ->
        :not_a_command

      {name, handler, arg_names, _arg_types} ->
        arg_values =
          message
          |> String.split()
          |> tl()

        arg_names = Enum.map(arg_names, &Atom.to_string/1)

        if length(arg_values) < length(arg_names) do
          {:too_few_args, name, length(arg_names), length(arg_values)}
        else
          {:ok, {name, handler, arg_names, arg_values}}
        end
    end
  end

  @spec execute({name(), atom(), arg_names(), arg_values()}, module()) :: any
  def execute({_name, handler, arg_names, arg_values}, module) do
    apply(module, handler, arg_values)
  end
end
