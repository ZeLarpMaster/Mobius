defmodule Mobius.Cache.Emoji do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_emoji(id) do
    Manager.get(@cache, id)
  end

  def update_emoji(server, %{id: id} = emoji) do
    Manager.update(server, @cache, id, emoji, &Map.merge/2)
  end

  def delete_emoji(server, id) do
    Manager.delete(server, @cache, id)
  end
end
