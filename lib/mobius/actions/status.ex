defmodule Mobius.Actions.Status do
  @moduledoc """
  Actions related to the bot's status on Discord
  """

  alias Mobius.Core.BotStatus
  alias Mobius.Core.Opcode
  alias Mobius.Services.Bot
  alias Mobius.Services.Socket

  @doc """
  Overwrite the bot's status to the given value

  This tries to change it on all shards,
  but there is no response so there is no guarantee the status actually changes
  """
  @spec change_status(BotStatus.t()) :: [:ok]
  def change_status(%BotStatus{} = new_status) do
    for shard <- Bot.list_shards() do
      new_status
      |> Opcode.update_status()
      |> Socket.send_message(shard)
    end
  end
end
