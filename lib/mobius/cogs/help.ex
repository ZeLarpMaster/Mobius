defmodule Mobius.Cogs.Help do
  @moduledoc "The help command's cog"

  use Mobius.Cog

  import Mobius.Actions.Message

  alias Mobius.Core.Command
  # Unsafe to use for 3rd party cogs
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

    cogs_list =
      cogs
      |> Enum.map(&format_cog/1)
      |> Enum.join("\n")

    send_message(%{content: "#{@header}```#{cogs_list}```#{@footer}"}, context.channel_id)
  end

  defp format_cog(%Mobius.Cog{name: name, commands: commands}) do
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
