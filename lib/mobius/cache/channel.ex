defmodule Mobius.Cache.Channel do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_channel(channel_id) do
    Manager.get(@cache, channel_id)
  end

  def update_channel(server, %{id: id} = channel) do
    Manager.update(server, @cache, id, channel, &Map.merge/2)
  end

  def delete_channel(server, id) do
    Manager.delete(server, @cache, id)
  end
end
