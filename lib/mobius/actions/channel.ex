defmodule Mobius.Actions.Channel do
  @moduledoc """
  Actions related to Discord channels such as fetching, modifying and deleting channels
  """

  import Mobius.Validations.ActionValidations

  alias Mobius.Models.Channel
  alias Mobius.Models.Snowflake
  alias Mobius.Rest
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot

  @type edit_channel_body :: Rest.Channel.edit_channel_body()

  @doc """
  Fetch a channel

  ## Example

      iex> get(132456789)
      {:ok, %Mobius.Models.Channel{} = channel}

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#get-channel
  """
  @spec get_channel(Snowflake.t()) :: Client.result(Channel.t())
  def get_channel(channel_id) do
    Rest.Channel.get_channel(Bot.get_client!(), channel_id)
  end

  @spec edit_channel(Snowflake.t(), edit_channel_body()) :: Client.result(Channel.t())
  def edit_channel(channel_id, params) do
    # TODO validate allow param fields based on channel type
    # TODO validate permissions

    validators = [
      string_length_validator(:name, 2, 100),
      &validate_channel_type/1,
      string_length_validator(:topic, 0, 1024),
      integer_range_validator(:rate_limit_per_user, 0, 21_600),
      integer_range_validator(:bitrate, 8000, 96_000),
      integer_range_validator(:user_limit, 0, 99)
    ]

    case validate_params(params, validators) do
      :ok -> Rest.Channel.edit_channel(Bot.get_client!(), channel_id, params)
      {:error, errors} -> {:error, errors}
    end
  end

  @spec delete_channel(Snowflake.t()) :: Client.result(Channel.t())
  # TODO validate permissions
  def delete_channel(channel_id), do: Rest.Channel.delete_channel(Bot.get_client!(), channel_id)

  defp validate_channel_type(%{type: type}) when type in [:guild_text, :guild_news], do: :ok

  defp validate_channel_type(%{type: _type}),
    do: {:error, "Channel type can only be converted to text or news"}

  defp validate_channel_type(_params), do: :ok
end
