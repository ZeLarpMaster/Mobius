defmodule Mobius.Shard.Gatekeeper.TimedTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mobius.{Fixtures, Assertions}

  alias Mobius.Shard.Gatekeeper.Timed, as: TimedGatekeeper

  @moduletag gatekeeper_impl: TimedGatekeeper
  @timeout Application.fetch_env!(:mobius, :time_between_connections_ms)

  setup :create_gatekeeper
  setup :start_connecting_tasks

  @tag tasks: 2
  test "doesn't let two in at the same time" do
    # Only one of the two connects
    assert_receive {:connecting, _pid}
    refute_receive {:connecting, _pid}
  end

  @tag tasks: 2
  test "waits for ack before unblocking the next some time later" do
    assert_receive {:connecting, task_pid}
    send(task_pid, :connect)
    assert_receive :connected

    # It doesn't connect until after the time between connections
    refute_receive {:connecting, _pid}, @timeout
    assert_receive {:connecting, other_pid}
    assert other_pid != task_pid
  end

  @tag tasks: 2
  test "moves on to the next when currently connecting process dies" do
    assert_receive {:connecting, task_pid}
    send(task_pid, :shutdown)

    # It still waits for the timeout when the process dies
    refute_receive {:connecting, _pid}, @timeout
    assert_receive {:connecting, other_pid}

    assert other_pid != task_pid
  end

  @tag tasks: 1
  test "connects immediately after waiting longer than the timeout", %{gatekeeper: gatekeeper} do
    assert_receive {:connecting, task_pid}
    send(task_pid, :shutdown)

    Process.sleep(@timeout * 2)
    # This might randomly fail on very slow CPUs
    assert_function_time(5, fn -> TimedGatekeeper.wait_until_can_identify(gatekeeper) end)
  end

  @tag tasks: 2
  test "warns when other process tries to ack", %{gatekeeper: gatekeeper} do
    assert_receive {:connecting, task_pid}

    log =
      capture_log(fn ->
        TimedGatekeeper.ack_identified(gatekeeper)
        # Wait until the other task is connecting to give time to the connection manager process
        send(task_pid, :connect)
        refute_receive {:connecting, _pid}, @timeout
        assert_receive {:connecting, other_pid}
      end)

    assert log =~ "someone else was identifying"
  end

  @tag tasks: 0
  test "warns when process acks more than once", %{gatekeeper: gatekeeper} do
    TimedGatekeeper.wait_until_can_identify(gatekeeper)
    TimedGatekeeper.ack_identified(gatekeeper)

    log =
      capture_log(fn ->
        TimedGatekeeper.ack_identified(gatekeeper)
        TimedGatekeeper.wait_until_can_identify(gatekeeper)
      end)

    assert log =~ "tried to ack again"
  end

  defp start_connecting_tasks(%{tasks: 0}), do: :ok

  defp start_connecting_tasks(%{gatekeeper: gatekeeper, tasks: n}) do
    for _ <- 1..n, do: start_connecting_task(gatekeeper, self())
    :ok
  end

  defp start_connecting_task(gatekeeper, pid) do
    spawn_link(fn -> connecting_task(gatekeeper, pid) end)
  end

  defp connecting_task(gatekeeper, pid) do
    TimedGatekeeper.wait_until_can_identify(gatekeeper)
    send(pid, {:connecting, self()})

    receive do
      :connect -> TimedGatekeeper.ack_identified(gatekeeper)
      :shutdown -> exit(:normal)
    end

    send(pid, :connected)
  end
end
