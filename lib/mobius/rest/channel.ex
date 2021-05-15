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
          optional(:parent_id) => Snowflake.t(),
          optional(:rtc_region) => String.t() | nil,
          optional(:video_quality_mode) => Channel.video_quality_mode()
        }

  @spec get_channel(Client.t(), Snowflake.t()) :: Client.result(Channel.t())
  def get_channel(client, channel_id) do
    client
    |> Tesla.get("/channels/:channel_id", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(&Channel.parse/1)
  end

  @spec edit_channel(Client.t(), Snowflake.t(), edit_channel_body()) :: Client.result(Channel.t())
  def edit_channel(client, channel_id, params) do
    params =
      params
      # TODO: |> update_param(:type, &convert_type/1)
      |> update_param(:video_quality_mode, &convert_video_quality_mode/1)

    client
    |> Tesla.patch("/channels/:channel_id", params, opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(&Channel.parse/1)
  end

  defp convert_video_quality_mode(:auto), do: 1
  defp convert_video_quality_mode(:full), do: 2

  defp update_param(map, param, fun) when is_map_key(map, param), do: Map.update!(map, param, fun)
  defp update_param(map, _param, _fun), do: map
end
