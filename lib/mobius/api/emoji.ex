defmodule Mobius.Api.Emoji do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec create_emoji(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def create_emoji(client, guild_id, params) do
    body = %{
      "name" => Keyword.fetch!(params, :name),
      "image" => Keyword.fetch!(params, :image),
      "roles" => Keyword.fetch!(params, :role_ids)
    }

    Tesla.post(client, "/guilds/:guild_id/emojis", body, opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Emoji, :parse_emoji)
  end

  @spec delete_emoji(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def delete_emoji(client, guild_id, emoji_id) do
    Tesla.delete(client, "/guilds/:guild_id/emojis/:emoji_id",
      opts: [path_params: [guild_id: guild_id, emoji_id: emoji_id]]
    )
    |> Client.check_empty_response()
  end

  @spec get_emoji(Tesla.Client.t(), Snowflake.t(), Snowflake.t()) :: {:ok, map} | Client.error()
  def get_emoji(client, guild_id, emoji_id) do
    Tesla.get(client, "/guilds/:guild_id/emojis/:emoji_id",
      opts: [path_params: [guild_id: guild_id, emoji_id: emoji_id]]
    )
    |> Client.parse_response(Parsers.Emoji, :parse_emoji)
  end

  @spec list_emojis(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_emojis(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/emojis", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Emoji, :parse_emoji)
  end

  @spec edit_emoji(Client.client(), Snowflake.t(), Snowflake.t(), keyword) ::
          {:ok, map} | Client.error()
  def edit_emoji(client, guild_id, emoji_id, params) do
    body =
      [
        {"name", :name},
        {"roles", :role_ids}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_, v} -> v != :unknown end)
      |> Map.new()

    Tesla.patch(client, "/guilds/:guild_id/emojis/:emoji_id", body,
      opts: [path_params: [guild_id: guild_id, emoji_id: emoji_id]]
    )
    |> Client.parse_response(Parsers.Emoji, :parse_emoji)
  end
end
