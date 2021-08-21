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
      model: Mobius.Models.Channel
    },
    %Endpoint{
      name: :delete_channel,
      url: "/channels/:channel_id",
      method: :delete,
      params: [{:channel_id, :snowflake}],
      model: Mobius.Models.Channel
    }
  ])

  def validate_channel_type(type) when type in [:guild_text, :guild_news], do: :ok

  def validate_channel_type(type),
    do: {:error, "to be either :guild_text or :guild_news, got #{type}"}
end
