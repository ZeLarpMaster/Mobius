defmodule Mobius.Models.Application do
  @moduledoc """
  Struct for the response of a GET /oauth2/applications/@me request

  Related documentation:
  https://discord.com/developers/docs/topics/oauth2#application-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.Team
  alias Mobius.Models.User

  defstruct [
    :id,
    :name,
    :icon,
    :description,
    # :rpc_origins, Only for RPC apps
    :bot_public,
    :bot_require_code_grant,
    :owner,
    # :summary, Only for games sold on Discord
    # :verify_key, Only for the GameSDK
    :team
    # :guild_id, Only for games sold on Discord
    # :primary_sku_id, Only for games sold on Discord
    # :slug, Only for games sold on Discord
    # :cover_image, Only for games sold on Discord
    # :flags, Unknown when we receive the field or what it means
  ]

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          icon: String.t() | nil,
          description: String.t(),
          bot_public: boolean,
          bot_require_code_grant: boolean,
          owner: User.partial(),
          team: Team.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :icon)
    |> add_field(map, :description)
    |> add_field(map, :bot_public)
    |> add_field(map, :bot_require_code_grant)
    |> add_field(map, :owner, &User.parse/1)
    |> add_field(map, :team, &Team.parse/1)
  end

  def parse(_), do: nil
end
