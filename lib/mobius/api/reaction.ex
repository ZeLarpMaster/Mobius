defmodule Mobius.Api.Reaction do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec create_reaction(Client.client(), Snowflake.t(), Snowflake.t(), binary) ::
          :ok | Client.error()
  def create_reaction(client, channel_id, message_id, emoji) do
    Tesla.put(client, "/channels/:channel_id/messages/:message_id/reactions/:emoji/@me", "",
      opts: [
        path_params: [channel_id: channel_id, message_id: message_id, emoji: encode_emoji(emoji)]
      ]
    )
    |> Client.check_empty_response()
  end

  @spec delete_own_reaction(Client.client(), Snowflake.t(), Snowflake.t(), binary) ::
          :ok | Client.error()
  def delete_own_reaction(client, channel_id, message_id, emoji) do
    Tesla.delete(client, "/channels/:channel_id/messages/:message_id/reactions/:emoji/@me",
      opts: [
        path_params: [channel_id: channel_id, message_id: message_id, emoji: encode_emoji(emoji)]
      ]
    )
    |> Client.check_empty_response()
  end

  @spec delete_reaction(Client.client(), Snowflake.t(), Snowflake.t(), binary, Snowflake.t()) ::
          :ok | Client.error()
  def delete_reaction(client, channel_id, message_id, emoji, user_id) do
    Tesla.delete(client, "/channels/:channel_id/messages/:message_id/reactions/:emoji/:user_id",
      opts: [
        path_params: [
          channel_id: channel_id,
          message_id: message_id,
          emoji: encode_emoji(emoji),
          user_id: user_id
        ]
      ]
    )
    |> Client.check_empty_response()
  end

  @spec list_reactions(Client.client(), Snowflake.t(), Snowflake.t(), binary, keyword) ::
          {:ok, list} | Client.error()
  def list_reactions(client, channel_id, message_id, emoji, params) do
    Tesla.get(client, "/channels/:channel_id/messages/:message_id/reactions/:emoji",
      query: Keyword.take(params, [:before, :after, :limit]),
      opts: [
        path_params: [channel_id: channel_id, message_id: message_id, emoji: encode_emoji(emoji)]
      ]
    )
    |> Client.parse_response(Parsers.User, :parse_user)
  end

  @spec delete_all_reactions(Client.client(), Snowflake.t(), Snowflake.t()) ::
          :ok | Client.error()
  def delete_all_reactions(client, channel_id, message_id) do
    Tesla.delete(client, "/channels/:channel_id/messages/:message_id/reactions",
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.check_empty_response()
  end

  @spec delete_all_reactions_for_emoji(Client.client(), Snowflake.t(), Snowflake.t(), binary) ::
          :ok | Client.error()
  def delete_all_reactions_for_emoji(client, channel_id, message_id, emoji) do
    Tesla.delete(client, "/channels/:channel_id/messages/:message_id/reactions/:emoji",
      opts: [
        path_params: [channel_id: channel_id, message_id: message_id, emoji: encode_emoji(emoji)]
      ]
    )
    |> Client.check_empty_response()
  end

  defp encode_emoji(emoji), do: URI.encode(emoji)
end
