defmodule Mobius.Models.Presence do
  @moduledoc """
  Struct for Discord's Presence

  Related documentation:
  https://discord.com/developers/docs/topics/gateway#presence-update
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Activity
  alias Mobius.Models.Snowflake

  defstruct [
    :user_id,
    :guild_id,
    :status,
    :activities,
    :client_status
  ]

  @type status :: :idle | :dnd | :online | :offline

  @type t :: %__MODULE__{
          user_id: Snowflake.t(),
          guild_id: Snowflake.t(),
          status: status(),
          activities: Activity.t(),
          client_status: map
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{user_id: Snowflake.parse(map["user"]["id"])}
    |> add_field(map, :guild_id, &Snowflake.parse/1)
    |> add_field(map, :status, &parse_status/1)
    |> add_field(map, :activities, &parse_activities/1)
    |> add_field(map, :client_status, &parse_statuses/1)
  end

  def parse(_), do: nil

  defp parse_status("idle"), do: :idle
  defp parse_status("dnd"), do: :dnd
  defp parse_status("online"), do: :online
  defp parse_status("offline"), do: :offline
  defp parse_status(_), do: nil

  defp parse_activities(activities), do: parse_list(activities, &Activity.parse/1)

  defp parse_statuses(statuses) when is_map(statuses) do
    Map.new(statuses, fn {k, v} -> {k, parse_status(v)} end)
  end

  defp parse_statuses(_), do: nil
end
