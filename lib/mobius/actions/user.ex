defmodule Mobius.Actions.User do
  @moduledoc """
  Functions for interacting with Discord users
  """

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Services.ModelCache

  @doc """
  Gets a user from the cache or returns `nil` if the user was not found in the cache

  ## Usage Caution
  When using this function, please keep in mind the caches aren't perfect.
  As stated in the
  [Discord documentation](https://discord.com/developers/docs/reference#consistency),
  events may never be sent to a client (this library).
  This means the cache may not contain things it should contain
  or may be out of date if an update event isn't sent (or received).

  If being up to date is very important to you,
  you may request up to date information with `get_user/1`
  """
  @spec get_cached_user(Snowflake.t()) :: User.t() | nil
  def get_cached_user(id), do: ModelCache.get(id, ModelCache.User)
end
