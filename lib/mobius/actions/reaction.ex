defmodule Mobius.Actions.Reaction do
  @moduledoc """
  Actions related to Discord reactions such as creating, removing and listing reactions.
  """

  alias Mobius.Actions
  alias Mobius.Endpoint
  alias Mobius.Models.Emoji
  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Rest
  alias Mobius.Services.Bot

  require Actions

  Actions.setup_actions([
    %Endpoint{
      name: :delete_own_reaction,
      url: "/channels/:channel_id/messages/:message_id/reactions/:emoji/@me",
      method: :delete,
      params: [{:emoji, :emoji}, {:channel_id, :snowflake}, {:message_id, :snowflake}],
      discord_doc_url:
        "https://discord.com/developers/docs/resources/channel#delete-own-reaction",
      doc: """
      Deletes one of your own reactions

      ## Example

          iex> emoji = %Mobius.Models.Emoji{name: "👌"}
          ...> Mobius.Actions.Reaction.delete_own_reaction(emoji, "123456789", "987654321")
          :ok
      """
    },
    %Endpoint{
      name: :delete_reaction,
      url: "/channels/:channel_id/messages/:message_id/reactions/:emoji/:user_id",
      method: :delete,
      params: [
        {:emoji, :emoji},
        {:channel_id, :snowflake},
        {:message_id, :snowflake},
        {:user_id, :snowflake}
      ],
      discord_doc_url:
        "https://discord.com/developers/docs/resources/channel#delete-user-reaction",
      doc: """
      Deletes another user's reaction

      ## Example

          iex> emoji = %Mobius.Models.Emoji{name: "👌"}
          ...> Mobius.Actions.Reaction.delete_reaction(emoji, "123456789", "987654321", "5432167890")
          :ok
      """
    },
    %Endpoint{
      name: :list_reactions,
      url: "/channels/:channel_id/messages/:message_id/reactions/:emoji",
      method: :get,
      params: [
        {:emoji, :emoji},
        {:channel_id, :snowflake},
        {:message_id, :snowflake}
      ],
      model: User,
      list_response?: true,
      discord_doc_url: "https://discord.com/developers/docs/resources/channel#get-reactions",
      doc: """
      List the users that reacted to the given message with the given emoji

      ## Example

          iex> emoji = %Mobius.Models.Emoji{name: "👌"}
          ...> Mobius.Actions.Reaction.list_reactions(emoji, "123456789", "987654321")
          {:ok, [%Mobius.Models.User{id: "234587098"}]}
      """
    },
    %Endpoint{
      name: :delete_all_reactions,
      url: "/channels/:channel_id/messages/:message_id/reactions",
      method: :delete,
      params: [
        {:channel_id, :snowflake},
        {:message_id, :snowflake}
      ],
      discord_doc_url:
        "https://discord.com/developers/docs/resources/channel#delete-all-reactions",
      doc: """
      Delete all reactions on the given message.

      ## Example

          iex> Mobius.Actions.Reaction.delete_all_reactions("123456789", "987654321")
          :ok
      """
    },
    %Endpoint{
      name: :delete_all_reactions_for_emoji,
      url: "/channels/:channel_id/messages/:message_id/reactions/:emoji",
      method: :delete,
      params: [
        {:emoji, :emoji},
        {:channel_id, :snowflake},
        {:message_id, :snowflake}
      ],
      discord_doc_url:
        "https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji",
      doc: """
      Delete all reactions with the given emoji on the given message.

      ## Example

          iex> emoji = %Mobius.Models.Emoji{name: "👌"}
          ...> Mobius.Actions.Reaction.delete_all_reactions_for_emoji(emoji, "123456789", "987654321")
          :ok
      """
    }
  ])

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
