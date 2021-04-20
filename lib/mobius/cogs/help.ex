defmodule Mobius.Cogs.Help do
  @moduledoc "The help command's cog"

  use Mobius.Cog

  import Mobius.Actions.Message

  # Unsafe to use for 3rd party cogs
  alias Mobius.Core.Cog
  alias Mobius.Core.Command
  alias Mobius.Services.CogLoader

  @header """
  Type `[p]help Cog` for help about a specific cog
  Type `[p]help command` for help about a specific command
  """

  @footer """
  Made with Mobius, a general purpose bot written in Elixir
  """

  @doc "This command"
  command "help", context do
    cogs = CogLoader.list_cogs()

    send_message(%{content: format_cogs(cogs)}, context.channel_id)
  end

  defp format_cogs(cogs) do
    cogs_list =
      cogs
      |> Enum.map(&format_cog/1)
      |> Enum.join("\n")

    "#{@header}```#{cogs_list}```#{@footer}"
  end

  defp format_cog(%Cog{name: name, commands: commands}) do
    commands_list =
      commands
      |> Enum.filter(fn %Command{description: description} -> description != false end)
      |> Enum.map(&format_command/1)
      |> Enum.join("\n")

    if commands_list == "" do
      "#{name}:\n    has no commands"
    else
      "#{name}:\n#{commands_list}"
    end
  end

  defp format_command(%Command{name: name, description: description}) do
    "    #{name}        #{description}"
  end
end
