defmodule Mobius.Actions.StatusTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Actions.Status
  alias Mobius.Core.BotStatus
  alias Mobius.Core.Opcode
  alias Mobius.Stubs.CommandsRatelimiter

  setup :reset_services
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard
  setup :handshake_shard

  describe "change_status/1" do
    test "sends the expected payload on the socket" do
      status =
        BotStatus.new()
        |> BotStatus.set_status(:idle)
        |> BotStatus.set_playing("A game")

      Status.change_status(status)

      payload = Opcode.update_status(status)
      assert_receive {:socket_msg, ^payload}
    end

    test "asks ratelimiter about update_status ratelimit", ctx do
      Status.change_status(BotStatus.new())

      expected_bucket = {"shard:#{ctx.shard.number}:update_status", 60_000, 5}
      assert_receive {:ratelimit_requested, ^expected_bucket}
    end

    test "asks ratelimiter about global ratelimit", ctx do
      Status.change_status(BotStatus.new())

      expected_bucket = {"shard:#{ctx.shard.number}:global", 60_000, 115}
      assert_receive {:ratelimit_requested, ^expected_bucket}
    end

    test "returns :ratelimited if ratelimited" do
      CommandsRatelimiter.set_ratelimited(true)

      assert [{:error, :ratelimited}] == Status.change_status(BotStatus.new())
    end
  end
end
