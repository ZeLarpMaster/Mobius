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
      send_command_payload("reply hello")

      assert_receive "hello"
    end

    test "should parse integer arguments" do
      send_command_payload("add 1 2")

      assert_receive 3
    end

    test "should notify of wrong number of arguments" do
      assert capture_log(fn ->
               send_command_payload("add 1")
               Process.sleep(10)
             end) =~
               "Wrong number of arguments for command \"add\". Expected 2 arguments, got 1."
    end

    test "should notify of invalid arguments" do
      assert capture_log(fn ->
               send_command_payload("add 2 hello")
               Process.sleep(10)
             end) =~
               ~s'Invalid type for argument "num2". Expected "integer", got "hello".'
    end
  end

  describe "command/4" do
    test "should be called with the context and the parsed arguments" do
      message = send_command_payload("everything 123")

      assert_receive {:everything, ^message, 123}
    end
  end
end
