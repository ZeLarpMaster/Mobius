defmodule Mobius.Cogs.Help do
  @moduledoc "The help command's cog"

  use Mobius.Cog

  alias Mobius.CogUtils
  # Unsafe to use for 3rd party cogs
  alias Mobius.Core.Cog
  alias Mobius.Core.Command
  alias Mobius.Services.CogLoader

  @help_footer """
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
  command "help" do
    CogLoader.list_cogs()
    |> format_cog_list()
    |> reply()
  end

  @doc """
  Shows help for a cog or a command

  The name is case sensitive to distinguish between cog names and command names.
  For example `[p]help Help` shows the cog, but `[p]help help` shows the command.
  """
  command "help", cog_or_command_name: :string do
    cogs = CogLoader.list_cogs()

    content =
      with nil <- try_cog(cog_or_command_name, cogs),
           nil <- try_command(cog_or_command_name, cogs) do
        @not_found
      end

    reply(content)
  end

  defp reply(content) do
    {:reply, %{content: content, allowed_mentions: %{parse: []}}}
  end

  defp try_cog(part, cogs) do
    case find_cog(part, cogs) do
      %Cog{} = cog -> format_cog(cog)
      _ -> nil
    end
  end

  defp try_command(part, cogs) do
    case find_command(part, cogs) do
      arities when is_map(arities) -> format_command(arities)
      _ -> nil
    end
  end

  defp format_cog(%Cog{} = cog) do
    commands = list_cog_commands(cog)
    formatted_commands = CogUtils.format_categories_list([{"Commands", commands}])

    "#{cog.description}\n```#{formatted_commands}```#{@cog_footer}"
  end

  defp format_command(arities) do
    arities
    |> Enum.flat_map(fn {_arity, clauses} -> clauses end)
    |> Enum.sort_by(&Command.arg_count/1)
    |> Enum.map(&format_clause/1)
    |> Enum.join("\n\n")
  end

  defp format_clause(%Command{} = clause) do
    args =
      clause.args
      |> Enum.map(fn {name, type} -> " {#{name} (#{type})}" end)
      |> Enum.join()

    "**`[p]#{clause.name}#{args}`**\n#{clause.description}"
  end

  defp format_cog_list(cogs) do
    cogs_list =
      cogs
      |> Enum.filter(fn %Cog{description: description} -> description != false end)
      |> Enum.map(fn %Cog{name: name} = cog -> {name, list_cog_commands(cog)} end)
      |> CogUtils.format_categories_list("has no commands")

    "```#{cogs_list}```#{@help_footer}"
  end

  defp list_cog_commands(%Cog{commands: commands}) do
    commands
    |> Enum.sort_by(fn {name, _clauses} -> name end)
    |> Enum.map(fn {name, arities} -> {name, Command.find_command_description(arities)} end)
  end

  defp find_cog(cog_name, cogs) do
    Enum.find(cogs, fn %Cog{name: name} -> name == cog_name end)
  end

  defp find_command(command_name, cogs) do
    Enum.find_value(cogs, fn %Cog{commands: commands} -> Map.get(commands, command_name) end)
  end
end
