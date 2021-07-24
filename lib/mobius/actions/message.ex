defmodule Mobius.Actions.Message do
  @moduledoc """
  Actions related to Discord messages such as sending, editing, and deleting messages
  """

  import Mobius.Validations.ActionValidations

  alias Mobius.Models.Message
  alias Mobius.Rest
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot

  @type file :: Rest.Message.file()
  @type message_body :: Rest.Message.message_body()

  @doc """
  Send a message in a channel

  The overall limit of the request is 8MB which includes files sent.
  Keep this in mind when sending potentially large messages.

  The params for the body of the message can be:
    - `content`: The message's content (maximum 2000 chars)
    - `nonce`: random string or integer to compare with received messages and check its reception
    - `tts`: true if this message should be read with tts
    - `file`: a `{content, filename}` tuple (see File Uploads below for details)
    - `embed`: an embed with type `rich` and some restrictions (see Discord docs)
    - `allowed_mentions`: the mentions allowed in this message (see Discord docs)
    - `message_reference`: identifies the message being replied to (see Discord docs)

  You must provide at least one of `content`, `embed` or `file`.

  ## File Uploads

  The `file` param in the body is the tuple `{content, filename}` where
  `content` is `t:iodata/0` or a `Stream` of `t:binary/0` and `filename` is a string

  You can use an uploaded image inside the same message's embed by using
  `"attachment://" <> filename` as the image url in the embed.
  This only works if the filename has a proper file extension (such as ".png", ".jpg", etc.)

  ## Example

      iex> send_message(%{content: "Some content"}, channel_id)
      {:ok, %Mobius.Models.Message{} = message}

  ## Documentation

  Refer to the documentation for details on the limitations given by Discord.
  This function handles both `content-type: application/json` and
  `content-type: multipart/form-data` (which is used when also sending a file).
  The implementation deals with how to send the parameters
  depending on which content type is used.

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#create-message
  """
  @spec send_message(message_body(), Snowflake.t()) :: Client.result(Message.t())
  def send_message(body, channel_id) do
    cond do
      not Enum.any?([:content, :embed, :file], &Map.has_key?(body, &1)) ->
        {:error, "Must have at least one of content, embed or file when sending a message"}

      String.length(Map.get(body, :content, "")) > 2000 ->
        {:error, "Content is too long (maximum 2000 characters)"}

      # TODO: Validate the embed limits (see https://discord.com/developers/docs/resources/channel#embed-limits)
      # TODO: Make sure the channel exists (requires a cache)
      # TODO: Make sure permissions are right (requires a cache)

      not Bot.ready?() ->
        {:error, "The bot must be ready before sending messages"}

      true ->
        Rest.Message.send_message(Bot.get_client!(), channel_id, body)
    end
  end

  def list_messages(channel_id, params) do
    # TODO: Validate permissions
    # TODO: Make sure the cannel exists (requires a cache)

    validators = [integer_range_validator(:limit, 1, 100)]

    case validate_params(params, validators) do
      :ok -> Rest.Message.list_messages(Bot.get_client!(), channel_id, params)
      {:error, errors} -> {:error, errors}
    end
  end
end
