defmodule Mobius.Actions.Reaction do
  @moduledoc """
  Actions related to Discord reactions such as creating, removing and listing reactions.
  """

  alias Mobius.Models.Emoji
  alias Mobius.Models.Snowflake
  alias Mobius.Rest
  alias Mobius.Services.Bot

  @doc """
  Add a reaction to a message

  ## Example

      iex> emoji = %Mobius.Models.Emoji{name: "👌", require_colons: false, managed: false, animated: false, available: true}
      ...> Mobius.Actions.Reaction.create_reaction(emoji, channel_id, message_id)
      :ok

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-reaction
  """
  @spec create_reaction(Emoji.t(), Snowflake.t(), Snowflake.t()) ::
          Client.empty_result() | {:error, String.t()}
  def create_reaction(%Emoji{} = emoji, channel_id, message_id) do
    with string when is_binary(string) <- get_emoji_string(emoji) do
      Rest.Reaction.create_reaction(
        Bot.get_client!(),
        channel_id,
        message_id,
        string
      )
    end
  end

  defp get_emoji_string(%Emoji{managed: true, id: nil}) do
    {:error, "Custom emojis require an ID"}
  end

  defp get_emoji_string(%Emoji{managed: true, name: nil}) do
    {:error, "Custom emojis require a name"}
  end

  defp get_emoji_string(%Emoji{managed: true} = emoji) do
    "#{emoji.name}:#{emoji.id}"
  end

  defp get_emoji_string(%Emoji{managed: false, name: nil}) do
    {:error, "Built-in emojis require a name"}
  end

  defp get_emoji_string(%Emoji{managed: false} = emoji) do
    emoji.name
  end
end
