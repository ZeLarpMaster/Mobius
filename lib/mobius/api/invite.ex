defmodule Mobius.Api.Invite do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec list_guild_invites(Client.client(), Snowflake.t()) :: {:ok, list} | Client.error()
  def list_guild_invites(client, guild_id) do
    Tesla.get(client, "/guilds/:guild_id/invites", opts: [path_params: [guild_id: guild_id]])
    |> Client.parse_response(Parsers.Invite, :parse_invite)
  end

  @spec list_channel_invites(Client.client(), Snowflake.t()) :: {:ok, map} | Client.error()
  def list_channel_invites(client, channel_id) do
    Tesla.get(client, "/channels/:channel_id/invites",
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(Parsers.Invite, :parse_invite)
  end

  @spec get_invite(Client.client(), String.t(), keyword) :: {:ok, map} | Client.error()
  def get_invite(client, invite_code, params) do
    query = [
      with_counts: Keyword.get(params, :with_counts?, false)
    ]

    Tesla.get(client, "/invites/:invite_code",
      query: query,
      opts: [path_params: [invite_code: invite_code]]
    )
    |> Client.parse_response(Parsers.Invite, :parse_invite)
  end

  @spec create_invite(Client.client(), Snowflake.t(), keyword) ::
          {:ok, map} | Client.error()
  def create_invite(client, channel_id, params) do
    body =
      [
        {"max_age", :max_age},
        {"max_uses", :max_uses},
        {"temporary", :temporary?},
        {"unique", :unique?},
        {"target_user", :target_user_id},
        {"target_user_type", :target_user_type}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_, v} -> v != :unknown end)
      |> Map.new()

    Tesla.post(client, "/channels/:channel_id/invites", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(Parsers.Invite, :parse_invite)
  end

  @spec delete_invite(Client.client(), String.t()) :: {:ok, map} | Client.error()
  def delete_invite(client, invite_code) do
    Tesla.delete(client, "/invites/:invite_code", opts: [path_params: [invite_code: invite_code]])
    |> Client.parse_response(Parsers.Invite, :parse_invite)
  end
end
