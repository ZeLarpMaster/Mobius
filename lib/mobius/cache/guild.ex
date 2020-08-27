defmodule Mobius.Cache.Guild do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_guild(guild_id) do
    Manager.get(@cache, guild_id)
  end

  def update_guild(server, %{id: guild_id} = guild) do
    Manager.update(server, @cache, guild_id, guild, &Map.merge/2)
  end

  def delete_guild(server, guild_id) do
    Manager.delete(server, @cache, guild_id)
  end
end
