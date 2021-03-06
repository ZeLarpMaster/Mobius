defmodule Mobius.Actions.Message do
  @moduledoc """
  Actions related to Discord messages such as sending, editing, and deleting messages
  """

  alias Mobius.Models.Message
  alias Mobius.Rest
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot

  @type message_body :: Rest.Message.message_body()

  @doc """
  Send a message in a channel

  The params can be:
    - `content`: The message's content (maximum 2000 chars)
    - `nonce`: random string or integer to compare with received messages and check its reception
    - `tts`: true if this message should be read with tts
    - `embed`: an embed with type `rich` and some restrictions (see Discord docs)
    - `allowed_mentions`: the mentions allowed in this message (see Discord docs)
    - `message_reference`: identifies the message being replied to (see Discord docs)

  ## Example

      iex> send_message([content: "Some content"], channel_id)
      {:ok, %Mobius.Models.Message{} = message}

  ## Documentation

  Refer to the documentation for details on the limitations given by Discord.
  This function is specifically for `content-type: application/json`.
  See `send_file/3` for `content-type: multipart/form-data`.

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-message
  """
  @spec send_message(message_body(), Snowflake.t()) :: Client.result(Message.t())
  def send_message(body, channel_id) do
    cond do
      not Map.has_key?(body, :content) and not Map.has_key?(body, :embed) ->
        {:error, "Must have at least one of content or embed when sending a message"}

      String.length(Map.get(body, :content, "")) > 2000 ->
        {:error, "Content is too long (maximum 2000 characters)"}

      # TODO: Validate the embed limits (see https://discord.com/developers/docs/resources/channel#embed-limits)
      # TODO: Make sure the channel exists (requires a cache)
      # TODO: Make sure permissions are right (requires a cache)
      # TODO: Make sure the bot is connected to the gateway

      true ->
        Rest.Message.send_message(Bot.get_client!(), channel_id, body)
    end
  end
end
