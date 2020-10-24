defmodule Mobius.Actions.StatusTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Actions.Status
  alias Mobius.Core.BotStatus
  alias Mobius.Core.Opcode

  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  test "change_status/1 sends the expected payload on the socket" do
    status =
      BotStatus.new()
      |> BotStatus.set_status(:idle)
      |> BotStatus.set_playing("A game")

    Status.change_status(status)

    payload = Opcode.update_status(status)
    assert_receive {:socket_msg, ^payload}
  end
end
