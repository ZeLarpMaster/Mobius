defmodule Mobius.Api.User do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client

  @spec get_current_user(Client.client()) :: {:ok, map} | Client.error()
  def get_current_user(client) do
    Tesla.get(client, "/users/@me")
    |> Client.parse_response(Parsers.User, :parse_user)
  end

  @spec edit_current_user(Client.client(), keyword) :: {:ok, map} | Client.error()
  def edit_current_user(client, params) do
    body =
      [
        {"username", :name},
        {"avatar", :avatar}
      ]
      |> Enum.map(fn {k, v} -> {k, Keyword.get(params, v, :unknown)} end)
      |> Enum.filter(fn {_k, v} -> v != :unknown end)
      |> Map.new()

    Tesla.patch(client, "/users/@me", body)
    |> Client.parse_response(Parsers.User, :parse_user)
  end

  @spec get_user(Client.client(), Snowflake.t()) :: {:ok, map} | Client.error()
  def get_user(client, user_id) do
    Tesla.get(client, "/users/:user_id", opts: [path_params: [user_id: user_id]])
    |> Client.parse_response(Parsers.User, :parse_user)
  end
end
