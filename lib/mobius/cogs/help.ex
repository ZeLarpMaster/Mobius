defmodule Mobius.Cogs.Help do
  @moduledoc "The help command's cog"

  use Mobius.Cog

  import Mobius.Actions.Message

  alias Mobius.CogUtils
  # Unsafe to use for 3rd party cogs
  alias Mobius.Core.Cog
  alias Mobius.Core.Command
  alias Mobius.Services.CogLoader

  @header """
  Type `[p]help Cog` for help about a specific cog
  Type `[p]help command` for help about a specific command
  """

  @cog_footer """
  Type `[p]help command` for help about a specific command
  """

  @not_found """
  Cog or command not found. Use `[p]help` for a list of cogs and commands.
  """

  @doc "This command"
  command "help", context do
    CogLoader.list_cogs()
    |> format_cogs()
    |> reply(context.channel_id)
  end

  @doc """
  Shows help for a cog or a command

  The name is case sensitive to distinguish between cog names and command names.
  For example `[p]help Help` shows the cog, but `[p]help help` shows the command.
  """
  command "help", context, cog_or_command_name: :string do
    cogs = CogLoader.list_cogs()

    cog_or_command_name
    |> try_cog(cogs)
    |> try_command(cog_or_command_name, cogs)
    |> reply(context.channel_id)
  end

  defp try_cog(part, cogs) do
    case find_cog(part, cogs) do
      %Cog{} = cog -> format_specific_cog(cog)
      _ -> nil
    end
  end

  defp try_command(content, _part, _cogs) when is_binary(content), do: content

  defp try_command(nil, part, cogs) do
    case find_command(part, cogs) do
      arities when is_map(arities) -> format_specific_command(arities)
      _ -> nil
    end
  end

  defp format_specific_cog(%Cog{} = cog) do
    commands = list_cog_commands(cog)
    command_list = CogUtils.format_categories_list([{"Commands", commands}])

    "#{cog.description}\n```#{command_list}```#{@cog_footer}"
  end

  defp format_specific_command(arities) do
    arities
    |> Enum.flat_map(fn {_arity, clauses} -> clauses end)
    |> Enum.sort_by(&Command.arg_count/1)
    |> Enum.map(&format_specific_clause/1)
    |> Enum.join("\n\n")
  end

  defp format_specific_clause(%Command{} = clause) do
    args =
      clause.args
      |> Enum.map(fn {name, type} -> " {#{name} (#{type})}" end)
      |> Enum.join()

    "**`[p]#{clause.name}#{args}`**\n#{clause.description}"
  end

  defp format_cogs(cogs) do
    cogs_list =
      cogs
      |> Enum.filter(fn %Cog{description: description} -> description != false end)
      |> Enum.map(fn %Cog{name: name} = cog -> {name, list_cog_commands(cog)} end)
      |> CogUtils.format_categories_list("has no commands")

    "#{@header}```#{cogs_list}```"
  end

  defp list_cog_commands(%Cog{commands: commands}) do
    commands
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {name, arities} -> {name, find_command_description(arities)} end)
  end

  defp find_command_description(arities) do
    arities
    |> Enum.min_by(&elem(&1, 0))
    |> elem(1)
    |> Enum.find_value("", fn %Command{description: description} -> description end)
  end

  defp find_cog(cog_name, cogs) do
    Enum.find(cogs, fn %Cog{name: name} -> name == cog_name end)
  end

  defp find_command(command_name, cogs) do
    Enum.find_value(cogs, fn %Cog{commands: commands} -> Map.get(commands, command_name) end)
  end

  defp reply(nil, channel_id), do: reply(@not_found, channel_id)

  defp reply(content, channel_id) do
    send_message(%{content: content, allowed_mentions: %{parse: []}}, channel_id)
  end
end
