defmodule Mobius.Services.BotTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mobius.Fixtures

  test "waits for the reset to start shards if no session starts left", ctx do
    # Bot will think there's 0 sessions left and it resets in 25ms
    mock_gateway_bot(0, 25)
    # Reset the mock after the test to not break all the following tests
    on_exit(&mock_gateway_bot/0)

    # If you have a better way of testing the execution of
    # `if remaining < shard_count do` in bot.ex, please open a PR
    assert capture_log(fn -> reset_services(ctx) end) =~
             "Too many connections were issued with this token! Waiting 25 milliseconds..."
  end
end
