defmodule Mobius.Actions.StatusTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Actions.Status
  alias Mobius.Core.BotStatus
  alias Mobius.Core.Opcode
  alias Mobius.Stubs

  setup :handshake_shard
  setup :stub_socket

  test "change_status/1 sends the expected payload on the socket", ctx do
    status =
      BotStatus.new()
      |> BotStatus.set_status(:idle)
      |> BotStatus.set_playing("A game")

    Status.change_status(status)

    ctx.socket
    |> Stubs.Socket.has_message?(fn msg ->
      status
      |> Opcode.update_status()
      |> Kernel.==(msg)
    end)
    |> assert
  end
end
