defmodule Mobius.Actions.Guild do
  @moduledoc """
  Functions for interacting with Discord guilds
  """

  alias Mobius.Models.Guild
  alias Mobius.Models.Snowflake
  alias Mobius.Services.ModelCache

  @doc """
  Gets a guild from the cache or returns `nil` if the guild was not found in the cache

  #{Mobius.Actions.Helpers.cache_caution("get_guild/1")}
  """
  @spec get_cached_guild(Snowflake.t()) :: Guild.t() | nil
  def get_cached_guild(id), do: ModelCache.get(id, ModelCache.Guild)
end
