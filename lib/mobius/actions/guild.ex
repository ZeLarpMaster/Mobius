defmodule Mobius.Actions.Guild do
  @moduledoc """
  Functions for interacting with Discord guilds
  """

  alias Mobius.Models.Guild
  alias Mobius.Models.Snowflake
  alias Mobius.Services.ModelCache

  @doc """
  Gets a guild from the cache or returns `nil` if the guild was not found in the cache

  ## Usage Caution
  When using this function, please keep in mind the caches aren't perfect.
  As stated in the
  [Discord documentation](https://discord.com/developers/docs/reference#consistency),
  events may never be sent to a client (this library).
  This means the cache may not contain everything you expect it to
  or may be out of date if an update event isn't sent (or received).

  If being up to date is very important to you,
  you may request up to date information with `get_guild/1`
  """
  @spec get_cached_guild(Snowflake.t()) :: Guild.t() | nil
  def get_cached_guild(id), do: ModelCache.get(id, ModelCache.Guild)
end
