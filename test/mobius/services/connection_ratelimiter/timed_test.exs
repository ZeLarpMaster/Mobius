defmodule Mobius.Services.ConnectionRatelimiter.TimedTest do
  use ExUnit.Case

  alias Mobius.Services.ConnectionRatelimiter.Timed

  @connection_delay 30
  @ack_timeout 50

  setup do
    # Manually start the service because it won't be started during tests
    # This also means it's restarted on every test
    # which means tests won't wait for the previous one to ack
    start_supervised!(
      {Timed, connection_delay_ms: @connection_delay, ack_timeout_ms: @ack_timeout}
    )

    :ok
  end

  describe "wait_until_can_connect/1" do
    test "executes the first callback immediately" do
      Timed.wait_until_can_connect(make_callback())
      assert_callback_called(0)
    end

    test "executes callbacks a delay after the previous ack" do
      Timed.wait_until_can_connect(make_callback())
      assert_received :callback_called
      Timed.ack_connected()
      Timed.wait_until_can_connect(make_callback())

      assert_callback_called(@connection_delay)
    end

    test "executes callbacks a delay after the previous ack timed out" do
      Timed.wait_until_can_connect(make_callback())
      assert_received :callback_called
      Timed.wait_until_can_connect(make_callback())

      assert_callback_called(@ack_timeout + @connection_delay)
    end

    test "executes callbacks a delay after the previous ack'er died" do
      # Start a task which connects then dies without ack'ing
      # and await that task to make the test wait for the task before continuing
      fn -> Timed.wait_until_can_connect(fn -> nil end) end
      |> Task.async()
      |> Task.await()

      Timed.wait_until_can_connect(make_callback())

      assert_callback_called(@connection_delay)
    end
  end

  defp assert_callback_called(0), do: assert_received(:callback_called)

  defp assert_callback_called(expected_time) do
    # Assert we receive at the expected time +- 10ms
    Process.sleep(expected_time - 10)
    assert_receive :callback_called, 20
  end

  defp make_callback do
    pid = self()
    fn -> send(pid, :callback_called) end
  end
end
