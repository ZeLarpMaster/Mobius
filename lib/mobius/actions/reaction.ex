defmodule Mobius.Actions.Reaction do
  alias Mobius.Rest
  alias Mobius.Services.Bot
  alias Mobius.Models.Snowflake

  @doc """
  Add a reaction to a message with a custom emoji

  ## Example

      iex> create_reaction(channel_id, message_id, "party_parrot", custom_emoji_id)
      :ok

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-reaction
  """
  @spec create_reaction(Snowflake.t(), Snowflake.t(), String.t(), Snowflake.t()) ::
          Client.empty_result()
  def create_reaction(channel_id, message_id, custom_emoji_name, custom_emoji_id) do
    Rest.Reaction.create_reaction(
      Bot.get_client!(),
      channel_id,
      message_id,
      "#{custom_emoji_name}:#{custom_emoji_id}"
    )
  end

  @doc """
  Add a reaction to a message with a Unicode emoji

  The emoji should be passed as its literal Unicode representation.

  ## Example

      iex> create_reaction(channel_id, message_id, "👌")
      :ok

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-reaction
  """
  @spec create_reaction(Snowflake.t(), Snowflake.t(), String.t()) :: Client.empty_result()
  def create_reaction(channel_id, message_id, unicode_emoji) do
    Rest.Reaction.create_reaction(Bot.get_client!(), channel_id, message_id, unicode_emoji)
  end
end
