defmodule Mobius.Models.Webhook do
  @moduledoc """
  Struct for Discord's Webhook

  Related documentation:
  https://discord.com/developers/docs/resources/webhook#webhook-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User

  defstruct [
    :id,
    :type,
    :guild_id,
    :channel_id,
    :user,
    :name,
    :avatar,
    :token,
    :application_id
  ]

  @type type :: :incoming | :channel_follower

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          type: type(),
          guild_id: Snowflake.t() | nil,
          channel_id: Snowflake.t(),
          user: User.t() | nil,
          name: String.t() | nil,
          avatar: String.t() | nil,
          token: String.t() | nil,
          application_id: Snowflake.t() | nil
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :channel_id, &Snowflake.parse/1)
    |> add_field(map, :user, &User.parse/1)
    |> add_field(map, :name)
    |> add_field(map, :avatar)
    |> add_field(map, :token)
    |> add_field(map, :application_id, &Snowflake.parse/1)
  end

  def parse(_), do: nil

  defp parse_type(1), do: :incoming
  defp parse_type(2), do: :channel_follower
  defp parse_type(_), do: nil
end
