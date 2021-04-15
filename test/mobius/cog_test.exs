defmodule Mobius.CogTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import ExUnit.CaptureLog

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  setup do
    Process.register(self(), :cog_test_process)
    start_supervised!(Mobius.Stubs.Cog)

    :ok
  end

  describe "listen/3" do
    test "should receive incoming listened events" do
      send_message_payload("some message content")

      assert_receive "some message content"
    end
  end

  describe "command/2" do
    test "should be called when a message starting with command name is received" do
      send_command_payload("nothing")

      assert_receive :nothing
    end

    test "raises when the command name has invalid characters" do
      assert_raise CompileError, ~r/must only contain/, fn ->
        defmodule InvalidCog do
          use Mobius.Cog

          command "hello world", do: nil
        end
      end
    end
  end

  describe "command/3" do
    test "should be called with the proper context if only a context is expected" do
      message = send_command_payload("send")

      assert_receive ^message
    end

    test "should be called when messages starting with command name are received" do
      send_command_payload("add hello")

      assert_receive {:unsupported, "hello"}
    end

    test "should call the clause with matching types" do
      send_command_payload("add 5")
      assert_receive 5
    end

    test "should notify of wrong number of arguments if no clause matches" do
      assert capture_log(fn ->
               send_command_payload("add")
               Process.sleep(10)
             end) =~
               "Wrong number of arguments. Expected one of 1, 2 arguments, got 0."
    end

    test "should notify of invalid arguments" do
      assert capture_log(fn ->
               send_command_payload("add 2 hello")
               Process.sleep(10)
             end) =~
               ~s'Type mismatch for the command "add" with 2 arguments'
    end
  end

  describe "command/4" do
    test "executes the first matching clause from top to bottom" do
      message = send_command_payload("everything 123")

      assert_receive {:everything, ^message, "123"}
    end
  end

  describe "undocumented cog" do
    defmodule UndocumentedCog do
      use Mobius.Cog
    end

    test "should have nil as a description" do
      assert nil == UndocumentedCog.__cog__().description
    end
  end

  describe "documented cog" do
    defmodule DocumentedCog do
      @moduledoc "This cog is documented"
      use Mobius.Cog

      @doc "Fun command"
      command "fun", do: nil

      @doc false
      command "hidden", do: nil

      command "nodoc", do: nil
    end

    test "should keep track of the cog's doc" do
      assert "This cog is documented" == DocumentedCog.__cog__().description
    end

    test "should keep track of command doc" do
      assert "Fun command" == get_command(DocumentedCog, "fun").description
    end

    test "should have false as command description if @doc false is given" do
      assert false == get_command(DocumentedCog, "hidden").description
    end

    test "should have nil as command description if no doc is given" do
      assert nil == get_command(DocumentedCog, "nodoc").description
    end
  end

  defp get_command(cog, command_name) do
    cog_info = cog.__cog__()
    hd(cog_info.commands[command_name][0])
  end
end
