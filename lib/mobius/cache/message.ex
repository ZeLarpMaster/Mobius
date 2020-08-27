defmodule Mobius.Cache.Message do
  @moduledoc false

  alias Mobius.Cache.Manager

  @cache __MODULE__
  @max_per_channel 50

  def cache_name, do: @cache

  def get_message(channel_id, message_id) do
    Manager.get(@cache, {channel_id, message_id})
  end

  def update_message(server, %{id: _, channel_id: _} = message) do
    Manager.custom(server, message, &insert_message/1)
  end

  def delete_message(server, channel_id, message_id) do
    Manager.custom(server, {channel_id, message_id}, &delete_message/1)
  end

  def delete_channel(server, channel_id) do
    Manager.custom(server, channel_id, &delete_channel/1)
  end

  defmacrop messages_in_channel(channel_id, return \\ :"$_") do
    quote do
      # Changing `return` overwrites the return value of the function
      # iex> :ets.fun2ms(fn {{^channel_id, _}, _} = v -> v end)
      [{{{:"$1", :_}, :_}, [{:"=:=", {:const, unquote(channel_id)}, :"$1"}], [unquote(return)]}]
    end
  end

  defp insert_message(%{id: id, channel_id: channel_id} = message) do
    case get_message(channel_id, id) do
      nil -> insert_new(channel_id, id, message)
      old_message -> update_existing(channel_id, id, old_message, message)
    end
  end

  defp insert_new(channel_id, id, message) do
    :ets.insert(@cache, {{channel_id, id}, message})
    count = get_channel_count(channel_id)

    if count > @max_per_channel do
      # Because the count is greater than @max_per_channel, we're guaranteed to find a value
      :ets.delete(@cache, find_oldest_key(channel_id))
    else
      # Increment the counter for the channel
      :ets.update_counter(@cache, {:count, channel_id}, 1, {nil, 0})
    end
  end

  defp delete_message({channel_id, message_id} = key) do
    case get_message(channel_id, message_id) do
      nil ->
        nil

      _ ->
        :ets.delete(@cache, key)
        :ets.update_counter(@cache, {:count, channel_id}, -1)
    end
  end

  defp get_channel_count(channel_id) do
    case :ets.lookup(@cache, {:count, channel_id}) do
      [{{:count, ^channel_id}, count}] -> count
      _ -> 0
    end
  end

  defp find_oldest_key(channel_id) do
    # O(number of messages + number of channels)
    {[{key, _value}], _continuation} = :ets.select(@cache, messages_in_channel(channel_id), 1)
    key
  end

  defp update_existing(channel_id, id, old_message, message) do
    message = Map.merge(old_message, message)
    :ets.insert(@cache, {{channel_id, id}, message})
  end

  defp delete_channel(channel_id) do
    # O(number of messages + number of channels)
    :ets.select_delete(@cache, messages_in_channel(channel_id, true))
    :ets.delete(@cache, {:count, channel_id})
  end
end
