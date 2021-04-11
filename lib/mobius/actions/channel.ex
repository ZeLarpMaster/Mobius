defmodule Mobius.Actions.Channel do
  @moduledoc """
  Actions related to Discord channels such as fetching, modifying and deleting channels
  """

  alias Mobius.Models.Channel
  alias Mobius.Models.Snowflake
  alias Mobius.Rest
  alias Mobius.Rest.Client
  alias Mobius.Services.Bot

  @doc """
  Fetch a channel

  ## Example

      iex> get(132456789)
      {:ok, %Mobius.Models.Channel{} = channel}

  ## Documentation

  Relevant documentation:
  https://discord.com/developers/docs/resources/channel#get-channel
  """
  @spec get(Snowflake.t()) :: Client.result(Channel.t())
  def get(channel_id) do
    Rest.Channel.get(Bot.get_client!(), channel_id)
  end
end
