defmodule Mobius.Api.Channel do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec get_channel(Client.client(), Snowflake.t()) :: {:ok, map} | Client.error()
  def get_channel(client, channel_id) do
    Tesla.get(client, "/channels/:channel_id", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec list_guild_channels(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_guild_channels(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/channels", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec create_channel(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def create_channel(client, guild_id, params) do
    body =
      [
        {"type", :type},
        {"topic", :topic},
        {"bitrate", :bitrate},
        {"user_limit", :user_limit},
        {"rate_limit_per_user", :slowmode_s},
        {"position", :position},
        {"permission_overwrites", :overwrites},
        {"parent_id", :parent_id},
        {"nsfw", :nsfw?}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_, v} -> v != :unknown end)
      |> Map.new()
      |> Map.put("name", Keyword.fetch!(params, :name))

    Tesla.post(client, "/guilds/:guild_id/channels", body,
      opts: [path_params: [guild_id: guild_id]]
    )
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec edit_channel(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def edit_channel(client, channel_id, params) do
    body =
      [
        {"name", Keyword.get(params, :name, :unknown)},
        {"type", Keyword.get(params, :type, :unknown)},
        {"position", Keyword.get(params, :position, :unknown)},
        {"topic", Keyword.get(params, :topic, :unknown)},
        {"nsfw", Keyword.get(params, :nsfw, :unknown)},
        {"rate_limit_per_user", Keyword.get(params, :slowmode_s, :unknown)},
        {"bitrate", Keyword.get(params, :bitrate, :unknown)},
        {"user_limit", Keyword.get(params, :user_limit, :unknown)},
        {"permission_overwrites", Keyword.get(params, :permissions, :unknown)},
        {"parent_id", Keyword.get(params, :parent_id, :unknown)}
      ]
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    unless map_size(body) > 0 do
      raise ArgumentError, message: "You must be changing something"
    end

    Tesla.patch(client, "/channels/:channel_id", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec edit_channel_positions(Client.client(), Snowflake.t(), [{Snowflake.t(), integer}]) ::
          :ok | Client.error()
  def edit_channel_positions(client, guild_id, pairs) do
    body =
      Enum.map(pairs, fn {channel_id, position} ->
        %{"id" => channel_id, "position" => position}
      end)

    Tesla.patch(client, "/guilds/:guild_id/channels", body,
      opts: [path_params: [guild_id: guild_id]]
    )
    |> Client.check_empty_response()
  end

  @spec delete_channel(Client.client(), Snowflake.t()) :: {:ok, map} | Client.error()
  def delete_channel(client, channel_id) do
    Tesla.delete(client, "/channels/:channel_id", opts: [path_params: [channel_id: channel_id]])
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec edit_channel_permissions(Client.client(), Snowflake.t(), Snowflake.t(), keyword) ::
          :ok | Client.error()
  def edit_channel_permissions(client, channel_id, overwrite_id, params) do
    body = %{
      "type" => Keyword.fetch!(params, :type),
      "allow" => Keyword.fetch!(params, :allow),
      "deny" => Keyword.fetch!(params, :deny)
    }

    Tesla.put(client, "/channels/:channel_id/permissions/:overwrite_id", body,
      opts: [path_params: [channel_id: channel_id, overwrite_id: overwrite_id]]
    )
    |> Client.check_empty_response()
  end

  @spec delete_channel_permission(Client.client(), Snowflake.t(), Snowflake.t()) ::
          :ok | Client.error()
  def delete_channel_permission(client, channel_id, overwrite_id) do
    Tesla.delete(client, "/channels/:channel_id/permissions/:overwrite_id",
      opts: [path_params: [channel_id: channel_id, overwrite_id: overwrite_id]]
    )
    |> Client.check_empty_response()
  end

  @spec create_dm(Client.client(), Snowflake.t()) :: {:ok, map} | Client.error()
  def create_dm(client, recipient_id) do
    body = %{"recipient_id" => recipient_id}

    Tesla.post(client, "/users/@me/channels", body)
    |> Client.parse_response(Parsers.Channel, :parse_channel)
  end

  @spec trigger_typing_indicator(Client.client(), Snowflake.t()) :: :ok | Client.error()
  def trigger_typing_indicator(client, channel_id) do
    Tesla.post(client, "/channels/:channel_id/typing", "",
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.check_empty_response()
  end
end
