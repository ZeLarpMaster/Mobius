defmodule Mobius.Actions.User do
  @moduledoc """
  Functions for interacting with Discord users
  """

  alias Mobius.Models.Snowflake
  alias Mobius.Models.User
  alias Mobius.Services.ModelCache

  @doc """
  Gets a user from the cache or returns `nil` if the user was not found in the cache

  #{Mobius.Actions.Helpers.cache_caution("get_user/1")}
  """
  @spec get_cached_user(Snowflake.t()) :: User.t() | nil
  def get_cached_user(id), do: ModelCache.get(id, ModelCache.User)
end
