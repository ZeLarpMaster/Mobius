defmodule Mobius.Config do
  @moduledoc """
  Defines a named config table

  Each config should have one scope (eg.: global, guild, user, member, channel, etc.)
  such that values specific to a user aren't sitting next to values specific to a channel.
  This is mainly to avoid filtering the values when querying them and thus avoid
  unnecessary operations.

  Configs will autosave to disk every few minutes
  and will be fully loaded into memory on startup.
  If you wish to manually save to be 100% sure it's saved when changed,
  you can do so with `save/0`.

  Configs are essentially persisted key-value stores,
  therefore operations like `stream/0` should be avoided when possible.
  """

  @config_location "data/"
  @config_suffix ".dump"
  @config_backup_suffix ".bak"

  @doc "Starts the config table with its name"
  @spec start(atom) :: :ok
  def start(config) do
    {:ok, _} = DynamicSupervisor.start_child(Mobius.Supervisor.Config, cache_spec(config))
    load(config)
    # TODO: Start a process which runs `save(config)` periodically iif the config was changed
    :ok
  end

  def put(config, key, value) do
    {:ok, true} = Cachex.put(config, key, value)
    :ok
  end

  def delete(config, key) do
    {:ok, true} = Cachex.del(config, key)
    :ok
  end

  def clear(config) do
    {:ok, size} = Cachex.clear(config)
    size
  end

  def get(config, key) do
    {:ok, value} = Cachex.get(config, key)
    value
  end

  def get_and_update(config, key, func), do: Cachex.get_and_update(config, key, func)

  def save(config) do
    backup_path = config_path(config, @config_backup_suffix)
    dump_path = config_path(config, @config_suffix)

    {:ok, true} = Cachex.dump(config, backup_path)
    :ok = File.rename(backup_path, dump_path)
  end

  defp load(config, suffix \\ @config_suffix) do
    path = config_path(config, suffix)

    cond do
      File.exists?(path) -> Cachex.load(config, path)
      suffix != @config_backup_suffix -> load(config, @config_backup_suffix)
      true -> :ok
    end
  end

  defp config_path(config, suffix) do
    Path.join(@config_location, [Atom.to_string(config), suffix])
  end

  defp cache_spec(name) do
    Supervisor.child_spec({Cachex, name: name}, id: name)
  end
end
