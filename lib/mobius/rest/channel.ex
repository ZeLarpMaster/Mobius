defmodule Mobius.Rest.Channel do
  @moduledoc false

  alias Mobius.Models.Channel
  alias Mobius.Models.PermissionsOverwrite
  alias Mobius.Models.Snowflake
  alias Mobius.Rest.Client

  @type edit_channel_body :: %{
          optional(:name) => String.t(),
          optional(:type) => Channel.type(),
          optional(:position) => integer(),
          optional(:topic) => String.t(),
          optional(:nsfw?) => boolean(),
          optional(:rate_limit_per_user) => integer(),
          optional(:bitrate) => integer(),
          optional(:user_limit) => integer(),
          optional(:permission_overwrites) => [PermissionsOverwrite.t()],
          optional(:parent_id) => Snowflake.t()
        }

  @spec get_channel(Client.t(), Snowflake.t()) :: Client.result(Channel.t())
  def get_channel(client, channel_id) do
    client
    |> Tesla.get("/channels/:channel_id", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(&Channel.parse/1)
  end

  @spec edit_channel(Client.t(), Snowflake.t(), edit_channel_body()) :: Client.result(Channel.t())
  def edit_channel(client, channel_id, params) do
    client
    |> Tesla.patch("/channels/:channel_id", params, opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(&Channel.parse/1)
  end
end
