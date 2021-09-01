defmodule Mobius.Cogs.HelpTest do
  use Mobius.CogCase, something: :test

  alias Mobius.Core.Cog
  alias Mobius.Services.CogLoader

  describe "[p]help" do
    test "has a footer describing the other commands" do
      send_command_payload("help")

      assert_message_sent(%{content: content})

      assert String.ends_with?(
               content,
               "Type `[p]help Cog` for help about a specific cog\n" <>
                 "Type `[p]help command` for help about a specific command\n"
             )
    end

    test "lists the cogs" do
      send_command_payload("help")

      assert_message_sent(%{content: content})

      CogLoader.list_cogs()
      |> Enum.all?(fn %Cog{name: name} -> content =~ name end)
      |> assert
    end

    test "lists itself and its command" do
      send_command_payload("help")

      assert_message_sent(%{content: content})
      assert content =~ "Help:\n  help    This command"
    end
  end

  describe "[p]help Cog/command" do
    test "replies with not found if no cog or command is found" do
      send_command_payload("help ----")

      assert_message_sent(%{content: content})
      assert content =~ "Cog or command not found"
    end

    test "replies with cog description if cog is found" do
      send_command_payload("help Help")

      assert_message_sent(%{content: content})
      assert content =~ "The help command's cog"
    end

    test "replies with cog commands if cog is found" do
      send_command_payload("help Help")

      assert_message_sent(%{content: content})
      assert content =~ "Commands:\n  help    This command"
    end

    test "replies with footer if cog is found" do
      send_command_payload("help Help")

      assert_message_sent(%{content: content})
      assert content =~ "Type `[p]help command` for help about a specific command"
    end

    test "replies with each clause if command is found" do
      send_command_payload("help help")

      assert_message_sent(%{content: content})
      assert content =~ "`[p]help`" and content =~ "`[p]help {cog_or_command_name (string)}`"
    end
  end
end
