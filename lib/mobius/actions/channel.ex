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

      iex> get_channel(132456789)
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
      {:name, string_length_validator(2, 100)},
      {:type, &validate_channel_type/1},
      {:topic, string_length_validator(0, 1024)},
      {:rate_limit_per_user, integer_range_validator(0, 21_600)},
      {:bitrate, integer_range_validator(8000, 96_000)},
      {:user_limit, integer_range_validator(0, 99)}
    ]

    case validate_params(params, validators) do
      :ok -> Rest.Channel.edit_channel(Bot.get_client!(), channel_id, params)
      {:error, errors} -> {:error, errors}
    end
  end

  @doc """
  Delete a channel

  ## Example

      iex> delete_channel(132456789)
      {:ok, %Mobius.Models.Channel{} = channel}

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#deleteclose-channel
  """
  @spec delete_channel(Snowflake.t()) :: Client.result(Channel.t())
  # TODO validate permissions
  def delete_channel(channel_id), do: Rest.Channel.delete_channel(Bot.get_client!(), channel_id)

  defp validate_channel_type(type) when type in [:guild_text, :guild_news], do: :ok

  defp validate_channel_type(type),
    do: {:error, "to be either :guild_text or :guild_news, got #{type}"}
end
