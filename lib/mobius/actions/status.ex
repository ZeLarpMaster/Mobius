defmodule Mobius.Actions.Status do
  @moduledoc """
  Actions related to the bot's status on Discord
  """

  alias Mobius.Core.BotStatus
  alias Mobius.Core.Opcode
  alias Mobius.Services.Bot
  alias Mobius.Services.CommandsRatelimiter
  alias Mobius.Services.Socket

  @doc """
  Overwrite the bot's status to the given value

  This tries to change it on all shards,
  but there is no response so there is no guarantee the status actually changes
  """
  @spec change_status(BotStatus.t()) :: [:ok | {:error, any}]
  def change_status(%BotStatus{} = new_status) do
    for shard <- Bot.list_shards() do
      # The "update_status" ratelimit of 5 per minute was found by testing a lot
      # because this limit is undocumented in the official documentation of the Discord API
      # This limit was also "confirmed" by another user on the unofficial Discord API server
      with :ok <- CommandsRatelimiter.request_access(shard, "update_status", 60_000, 5),
           :ok <- CommandsRatelimiter.request_access(shard) do
        new_status
        |> Opcode.update_status()
        |> Socket.send_message(shard)
      else
        :ratelimited -> {:error, :ratelimited}
      end
    end
  end
end
