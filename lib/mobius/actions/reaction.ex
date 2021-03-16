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

      iex> emoji = %Mobius.Models.Emoji{name: "👌"}
      ...> Mobius.Actions.Reaction.create_reaction(emoji, channel_id, message_id)
      :ok

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-reaction
  """
  @spec create_reaction(Emoji.t(), Snowflake.t(), Snowflake.t()) ::
          Client.empty_result()
  def create_reaction(%Emoji{} = emoji, channel_id, message_id) do
    # TODO check for required permissions

    with string when is_binary(string) <- Emoji.get_identifier(emoji) do
      Rest.Reaction.create_reaction(
        Bot.get_client!(),
        channel_id,
        message_id,
        string
      )
    end
  end
end
