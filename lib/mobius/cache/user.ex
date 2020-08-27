defmodule Mobius.Cache.User do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_user(user_id) do
    Manager.get(@cache, user_id)
  end

  def update_user(server, %{id: user_id} = user) do
    Manager.update(server, @cache, user_id, user, &Map.merge/2)
  end

  def delete_user(server, user_id) do
    Manager.delete(server, @cache, user_id)
  end
end
