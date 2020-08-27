defmodule Mobius.Cache.Manager do
  @moduledoc false

  use GenServer

  alias Mobius.Cache
  alias Mobius.ETSShelf

  @bot_cache Cache.Bot.cache_name()
  @guild_cache Cache.Guild.cache_name()
  @channel_cache Cache.Channel.cache_name()
  @message_cache Cache.Message.cache_name()
  @user_cache Cache.User.cache_name()

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  def get(cache, key) do
    case :ets.lookup(cache, key) do
      [{^key, value}] -> value
      _ -> nil
    end
  end

  def update(server, cache, key, value, merge_fun) do
    GenServer.call(server, {:update, cache, key, value, merge_fun})
  end

  def delete(server, cache, key) do
    GenServer.call(server, {:delete, cache, key})
  end

  def custom(server, key, fun) do
    GenServer.call(server, {:custom, key, fun})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, map} | {:stop, any}
  def init(opts) do
    server = Keyword.fetch!(opts, :shelf)

    with :ok <- ETSShelf.create_table(server, @channel_cache, [:set, :protected]),
         :ok <- ETSShelf.create_table(server, @user_cache, [:set, :protected]),
         :ok <- ETSShelf.create_table(server, @message_cache, [:ordered_set, :protected]),
         :ok <- ETSShelf.create_table(server, @bot_cache, [:set, :protected]),
         :ok <- ETSShelf.create_table(server, @guild_cache, [:set, :protected]) do
      {:ok, %{}}
    else
      error -> {:stop, error}
    end
  end

  @impl GenServer
  def handle_call({:update, cache, key, value, merge_fun}, _from, state) do
    value = merge_value(cache, key, value, merge_fun)
    :ets.insert(cache, {key, value})
    {:reply, :ok, state}
  end

  def handle_call({:delete, cache, key}, _from, state) do
    :ets.delete(cache, key)
    {:reply, :ok, state}
  end

  def handle_call({:custom, key, fun}, _from, state) do
    fun.(key)
    {:reply, :ok, state}
  end

  defp merge_value(cache, key, value, merge_fun) do
    case get(cache, key) do
      nil -> value
      old_value -> merge_fun.(old_value, value)
    end
  end
end
