defmodule Mobius.Rest.Reaction do
  @moduledoc false

  alias Mobius.Rest.Client

  @doc """
  Does the API call for "Create Reaction"

  When creating reactions with custom emojis, formatting of the custom emoji
  name and ID is expected to be handled by the caller.
  """
  @spec create_reaction(Client.t(), Snowflake.t(), Snowflake.t(), String.t()) ::
          Client.empty_result()
  def create_reaction(client, channel_id, message_id, emoji) do
    client
    |> Tesla.put(
      "/channels/:channel_id/messages/:message_id/reactions/:emoji/@me",
      %{},
      opts: [
        path_params: [
          channel_id: channel_id,
          message_id: message_id,
          emoji: emoji
        ]
      ]
    )
    |> Client.check_empty_response()
  end
end
