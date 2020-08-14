defmodule Mobius.Parsers.Gateway do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Parsers.Utils

  @spec parse_gateway_bot(Utils.input(), Utils.path()) :: Utils.result()
  def parse_gateway_bot(value, path \\ nil) do
    [
      {:required, :url, "url"},
      {:required, :shards, "shards"},
      {:required, :session_start_limit,
       {:via, "session_start_limit", __MODULE__, :parse_session_start_limit}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_session_start_limit(Utils.input(), Utils.path()) :: Utils.result()
  def parse_session_start_limit(value, path \\ nil) do
    [
      {:required, :total, "total"},
      {:required, :remaining, "remaining"},
      {:required, :reset_after, "reset_after"}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_app_info(Utils.input(), Utils.path()) :: Utils.result()
  def parse_app_info(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "name"},
      {:required, :icon, "icon"},
      {:required, :description, "description"},
      {:optional, :rpc_origins, "rpc_origins"},
      {:required, :bot_public?, "bot_public"},
      {:required, :bot_require_code_grant?, "bot_require_code_grant"},
      {:required, :owner, {:via, "owner", Parsers.User, :parse_user}},
      {:required, :summary, "summary"},
      {:required, :verify_key, "verify_key"},
      {:required, :team, {:via, "team", __MODULE__, :parse_team}},
      {:optional, :guild_id, {:via, "guild_id", Utils, :parse_snowflake}},
      {:optional, :primary_sku_id, {:via, "primary_sky_id", Utils, :parse_snowflake}},
      {:optional, :slug, "slug"},
      {:optional, :cover_image, "cover_image"}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_team(Utils.input(), Utils.path()) :: Utils.result()
  def parse_team(value, path \\ nil) do
    [
      {:required, :icon, "icon"},
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :members, {:via, "members", __MODULE__, :parse_team_member}},
      {:required, :owner_user_id, {:via, "owner_user_id", Utils, :parse_snowflake}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_team_member(Utils.input(), Utils.path()) :: Utils.result()
  def parse_team_member(value, path \\ nil) do
    [
      {:required, :membership_state, {:via, "membership_state", __MODULE__, :parse_membership}},
      {:required, :permissions, "permissions"},
      {:required, :team_id, {:via, "team_id", Utils, :parse_snowflake}},
      {:required, :user, {:via, "user", Parsers.User, :parse_user}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_membership(integer, Utils.path()) :: atom | integer
  def parse_membership(1, _path), do: :invited
  def parse_membership(2, _path), do: :accepted
  def parse_membership(type, _path), do: type
end
