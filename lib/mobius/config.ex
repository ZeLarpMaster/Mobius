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

  @doc "Starts the config table with its name"
  @spec start(atom) :: Supervisor.on_start()
  def start(name) do
    DynamicSupervisor.start_child(Mobius.Supervisor.Config, cache_spec(name))
  end

  def put do
  end

  def delete do
  end

  def clear do
  end

  def get do
  end

  def get_and_update do
  end

  def save do
  end

  defp cache_spec(name) do
    Supervisor.child_spec({Cachex, name: name}, id: name)
  end
end
