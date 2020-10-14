defmodule Mobius.Core.HeartbeatInfoTest do
  use ExUnit.Case, async: true

  import Mobius.Core.HeartbeatInfo

  test "ping updates when ack'd after sending" do
    sending_info = sending(new())
    acked_info = received_ack(sending_info)
    assert acked_info.ping == acked_info.ack_stamp - sending_info.send_stamp
  end

  test "ping doesn't change if received ack without sending" do
    info = new() |> sending() |> received_ack()
    info2 = received_ack(info)
    assert info.ping == info2.ping
  end

  describe "can_send?/1" do
    test "true for a fresh info" do
      new()
      |> can_send?()
      |> assert
    end

    test "false if already sent" do
      new()
      |> sending()
      |> can_send?()
      |> refute
    end

    test "true if sent and received ack" do
      new()
      |> sending()
      |> received_ack()
      |> can_send?()
      |> assert
    end
  end
end
