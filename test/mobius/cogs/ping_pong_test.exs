defmodule Mobius.Cogs.PingPongTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import ExUnit.CaptureLog

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  setup do
    Process.register(self(), :cog_test_process)

    :ok
  end

  describe "command \"ping\"" do
    test "should reply \"pong\"" do
      capture_log(fn ->
        send_message_payload("ping")
      end) =~ "pong"
    end
  end
end
