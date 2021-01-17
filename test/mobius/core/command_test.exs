defmodule Mobius.Core.CommandTest do
  use ExUnit.Case, async: true

  alias Mobius.Core.Command

  describe "command_handler_name/1" do
    test "should return the name as a formatted atom" do
      assert Command.command_handler_name("some_name") == :__mobius_command_some_name__
    end
  end

  describe "arg_names/1" do
    test "should return the names of the arguments" do
      command = %Command{
        name: "hello",
        args: [
          foo: :integer,
          bar: :string,
          baz: :string
        ],
        handler: {:hello, 0}
      }

      assert Command.arg_names(command) == ["foo", "bar", "baz"]
    end
  end

  describe "arg_count/1" do
    test "should return the number of arguments" do
      command = %Command{
        name: "hello",
        args: [
          foo: :integer,
          bar: :string,
          baz: :string
        ],
        handler: {:hello, 0}
      }

      assert Command.arg_count(command) == 3
    end
  end

  describe "execute_command/2" do
    setup do
      command = %Command{
        name: "hello",
        args: [
          foo: :integer,
          bar: :string,
          baz: :string
        ],
        handler: &command_handler/3
      }

      [command: command]
    end

    test "should return an error when no command matches the message" do
      assert Command.execute_command([], "hello") == :not_a_command
    end

    test "should return an error when the command has missing arguments", %{command: command} do
      assert Command.execute_command([command], "hello") == {:too_few_args, command, 0}
    end

    test "should return an error when the command has invalid arguments", %{command: command} do
      assert Command.execute_command([command], "hello foo bar baz") ==
               {:invalid_args, [{{:foo, :integer}, "foo"}]}
    end

    test "should execute the command when the arguments are valid", %{command: command} do
      Command.execute_command([command], "hello 1 foo bar")
      assert_receive("command handled")
    end
  end

  defp command_handler(_, _, _) do
    send(self(), "command handled")
  end
end
