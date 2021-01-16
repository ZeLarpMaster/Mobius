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

  describe "command/3" do
    test "should be called when messages starting with command name are received" do
      send_message_payload("reply hello")

      assert_receive "hello"
    end

    test "should parse integer arguments" do
      send_message_payload("add 1 2")

      assert_receive 3
    end

    test "should notify of missing arguments" do
      assert capture_log(fn ->
               send_message_payload("add 1")
               Process.sleep(10)
             end) =~
               "Too few arguments for command \"add\". Expected 2 arguments, got 1."
    end

    test "should notify of invalid arguments" do
      assert capture_log(fn ->
               send_message_payload("add 2 hello")
               Process.sleep(10)
             end) =~
               ~s'Invalid type for argument "num2". Expected "integer", got "hello".'
    end
  end
end
