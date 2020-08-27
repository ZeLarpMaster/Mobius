defmodule Mobius.Cache.Bot do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__

  def cache_name, do: @cache

  def get_app_info() do
    Manager.get(@cache, :app_info)
  end

  def update_app_info(server, app_info) do
    Manager.update(server, @cache, :app_info, app_info, &Map.merge/2)
  end
end
