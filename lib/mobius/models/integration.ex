defmodule Mobius.Models.Integration do
  @moduledoc """
  Struct for Discord's Integration

  Related documentation:
  https://discord.com/developers/docs/resources/guild#integration-object
  """

  import Mobius.Model

  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  @behaviour Mobius.Model

  defstruct [
    :id,
    :name,
    :type,
    :enabled,
    :syncing,
    :role_id,
    :enable_emoticons,
    :expire_behavior,
    :expire_grace_period,
    :user,
    :account,
    :synced_at,
    :subscriber_count,
    :revoked,
    :application
  ]

  @type type :: :twitch | :youtube | :discord
  @type expire_behavior :: :remove_role | :kick

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          name: String.t(),
          type: type(),
          enabled: boolean,
          syncing: boolean | nil,
          role_id: Snowflake.t() | nil,
          enable_emoticons: boolean | nil,
          expire_behavior: expire_behavior() | nil,
          expire_grace_period: non_neg_integer() | nil,
          user: User.t() | nil,
          account: __MODULE__.Account.t(),
          synced_at: DateTime.t(),
          subscriber_count: non_neg_integer(),
          revoked: boolean,
          application: __MODULE__.Application.t()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :enabled)
    |> add_field(map, :syncing)
    |> add_field(map, :role_id, &Snowflake.parse/1)
    |> add_field(map, :enable_emoticons)
    |> add_field(map, :expire_behavior, &parse_behavior/1)
    |> add_field(map, :expire_grace_period)
    |> add_field(map, :user, &User.parse/1)
    |> add_field(map, :account, &__MODULE__.Account.parse/1)
    |> add_field(map, :synced_at, &Timestamp.parse/1)
    |> add_field(map, :subscriber_count)
    |> add_field(map, :revoked)
    |> add_field(map, :application, &__MODULE__.Application.parse/1)
  end

  def parse(_), do: nil

  defp parse_type("twitch"), do: :twitch
  defp parse_type("youtube"), do: :youtube
  defp parse_type("discord"), do: :discord
  defp parse_type(_), do: nil

  defp parse_behavior(0), do: :remove_role
  defp parse_behavior(1), do: :kick
  defp parse_behavior(_), do: nil
end
