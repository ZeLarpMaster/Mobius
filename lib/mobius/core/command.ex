defmodule Mobius.Core.Command do
  @moduledoc false

  @enforce_keys [:name, :args, :handler]
  defstruct [:name, :args, :handler]

  @type t :: %__MODULE__{
          name: String.t(),
          args: keyword(arg_type()),
          handler: function()
        }

  @type arg_type :: :string

  @spec command_handler_name(String.t()) :: atom()
  def command_handler_name(command_name) do
    :"mobius_command_#{command_name}"
  end

  @spec get_command_arg_names(keyword(atom())) :: [atom()]
  def get_command_arg_names(args) do
    args
    |> Enum.map(&elem(&1, 0))
  end

  @spec parse_command([t()], String.t()) ::
          :not_a_command
          | {:ok, t(), [String.t()]}
          | {:too_few_args, t(), non_neg_integer()}
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

        with {:ok, command} <- validate(command, arg_values) do
          {:ok, command, arg_values}
        end
    end
  end

  @spec validate(t(), [String.t()]) ::
          {:ok, t()} | {:too_few_args, t(), non_neg_integer()}
  def validate(%__MODULE__{} = command, values) do
    expected_count = arg_count(command)
    actual_count = length(values)

    if actual_count < expected_count do
      {:too_few_args, command, actual_count}
    else
      {:ok, command}
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
end
