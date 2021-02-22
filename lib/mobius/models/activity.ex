defmodule Mobius.Models.Activity do
  @moduledoc """
  Struct for Discord's Activity

  Related documentation:
  https://discord.com/developers/docs/topics/gateway#activity-object
  """

  import Mobius.Models.Utils

  alias Mobius.Models.Snowflake

  defstruct [
    :name,
    :type,
    :url,
    :created_at,
    :timestamps,
    :application_id,
    :details,
    :state,
    :emoji,
    :party,
    :assets,
    :secrets,
    :instance,
    :flags
  ]

  @flags [
    :instance,
    :join,
    :spectate,
    :join_request,
    :sync,
    :play
  ]

  @type type :: :game | :streaming | :listening | :custom | :competing
  @type flag :: :instance | :join | :spectate | :join_request | :sync | :play
  @type flags :: MapSet.t(flag)

  @type t :: %__MODULE__{
          name: String.t(),
          type: type(),
          url: String.t(),
          created_at: DateTime.t(),
          timestamps: map,
          application_id: Snowflake.t(),
          details: String.t(),
          state: String.t(),
          emoji: map,
          party: map,
          assets: map,
          secrets: map,
          instance: boolean,
          flags: flags()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :name)
    |> add_field(map, :type, &parse_type/1)
    |> add_field(map, :url)
    |> add_field(map, :created_at, &parse_timestamp/1)
    |> add_field(map, :timestamps)
    |> add_field(map, :application_id, &Snowflake.parse/1)
    |> add_field(map, :details)
    |> add_field(map, :state)
    |> add_field(map, :emoji)
    |> add_field(map, :party)
    |> add_field(map, :assets)
    |> add_field(map, :secrets)
    |> add_field(map, :instance)
    |> add_field(map, :flags, &parse_flags(&1, @flags))
  end

  def parse(_), do: nil

  defp parse_timestamp(stamp) when is_integer(stamp), do: DateTime.from_unix!(stamp, :millisecond)
  defp parse_timestamp(_), do: nil

  defp parse_type(0), do: :game
  defp parse_type(1), do: :streaming
  defp parse_type(2), do: :listening
  defp parse_type(4), do: :custom
  defp parse_type(5), do: :competing
  defp parse_type(_), do: nil
end
