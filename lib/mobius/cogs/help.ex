defmodule Mobius.Cogs.Help do
  @moduledoc "The help command's cog"

  use Mobius.Cog

  import Mobius.Actions.Message

  # Unsafe to use for 3rd party cogs
  alias Mobius.Services.CogLoader

  @doc "Wow"
  command "help", context do
    cogs = CogLoader.list_cogs()

    cogs_list =
      cogs
      |> Enum.map(&format_cog/1)
      |> Enum.join("\n")

    send_message(%{content: "```#{cogs_list}```"}, context.channel_id)
  end

  defp format_cog(%Mobius.Cog{name: name, commands: commands}) do
    commands_list =
      commands
      |> Enum.map(&format_command/1)
      |> Enum.join("\n")

    "#{name}:\n#{commands_list}"
  end

  defp format_command(%Mobius.Core.Command{name: name, description: description}) do
    "    #{name}        #{description}"
  end
end
