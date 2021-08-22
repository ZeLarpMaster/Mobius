defmodule Mobius.Actions.Channel do
  @moduledoc """
  Actions related to Discord channels such as fetching, modifying and deleting channels
  """

  import Mobius.Validations.ActionValidations

  alias Mobius.Actions
  alias Mobius.Endpoint
  alias Mobius.Rest

  require Actions

  @type edit_channel_body :: Rest.Channel.edit_channel_body()

  Actions.setup_actions([
    %Endpoint{
      name: :get_channel,
      url: "/channels/:channel_id",
      method: :get,
      params: [{:channel_id, :snowflake}],
      discord_doc_url: "https://discord.com/developers/docs/resources/channel#get-channel",
      doc: """
      Fetch a channel

      ## Example

          iex> get_channel("123456789")
          {:ok, %Mobius.Models.Channel{} = channel}
      """,
      model: Mobius.Models.Channel
    },
    %Endpoint{
      name: :edit_channel,
      url: "/channels/:channel_id",
      method: :patch,
      params: [{:channel_id, :snowflake}],
      opts: %{
        name: {:string, [min: 2, max: 100]},
        type: {__MODULE__, :validate_channel_type},
        topic: {:string, [min: 0, max: 1024]},
        rate_limit_per_user: {:integer, [min: 0, max: 21_600]},
        bitrate: {:integer, [min: 8000, max: 96_000]},
        user_limit: {:integer, [min: 0, max: 99]}
      },
      discord_doc_url: "https://discord.com/developers/docs/resources/channel#modify-channel",
      doc: """
      Edits a channel

      This function accepts the following options:
      - name: The name of the channel (between 2 and 100 characters).
      - type: The type of the channel. See `t:Mobius.Models.Channel.type/0` for
      the list of available types. Can only be converted from "text" to "news"
      and vice-versa, and only in guilds with the "NEWS" feature.
      - topic: The topic of the channel (between 0 and 1024 characters).
      - rate_limit_per_user: The number of seconds users have to wait between
      each sent message (between 0 and 21 600).
      - bitrate: The bitrate of the channel (voice channels only)
      (between 8000 and 96 000).
      - user_limit: The maximum number of users that can join the cannel (voice
      channels only) (between 0 and 99, 0 means unlimited).

      ## Example

          iex> edit_channel("123456789", name: "my new channel name")
          {:ok, %Mobius.Models.Channel{name: "my new channel name"} = channel}
      """,
      model: Mobius.Models.Channel
    },
    %Endpoint{
      name: :delete_channel,
      url: "/channels/:channel_id",
      method: :delete,
      params: [{:channel_id, :snowflake}],
      discord_doc_url:
        "https://discord.com/developers/docs/resources/channel#deleteclose-channel",
      doc: """
      Delete a channel

      ## Example

          iex> delete_channel("123456789")
          {:ok, %Mobius.Models.Channel{} = channel}
      """,
      model: Mobius.Models.Channel
    }
  ])

  def validate_channel_type(type) when type in [:guild_text, :guild_news], do: :ok

  def validate_channel_type(type),
    do: {:error, "to be either :guild_text or :guild_news, got #{type}"}
end
