defmodule Mobius.Cache.Role do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_role(guild_id, role_id) do
    Manager.get(@cache, {guild_id, role_id})
  end

  def update_role(server, guild_id, %{id: id} = role) do
    Manager.update(server, @cache, {guild_id, id}, role, &Map.merge/2)
  end

  def delete_role(server, guild_id, role_id) do
    Manager.delete(server, @cache, {guild_id, role_id})
  end

  def delete_guild(server, guild_id) do
    Manager.custom(server, guild_id, &delete_guild/1)
  end

  defmacrop roles_in_guild(guild_id, return \\ :"$_") do
    quote do
      # Changing `return` overwrites the return value of the function
      # iex> :ets.fun2ms(fn {{^guild_id, _}, _} = v -> v end)
      [{{{:"$1", :_}, :_}, [{:"=:=", {:const, unquote(guild_id)}, :"$1"}], [unquote(return)]}]
    end
  end

  defp delete_guild(guild_id) do
    # O(total number of roles)
    :ets.select_delete(@cache, roles_in_guild(guild_id, true))
  end
end
