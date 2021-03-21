defmodule Mobius.Core.ShardList do
  @moduledoc false

  alias Mobius.Core.ShardInfo

  require Ex2ms

  @doc "Options for the ETS table creation"
  @spec table_options() :: [atom]
  def table_options do
    [:ordered_set, :protected]
  end

  @doc "Lists all shards regardless of state"
  @spec list_shards(:ets.tab()) :: [ShardInfo.t()]
  def list_shards(table) do
    shards = :ets.match(table, {:"$1", :_})
    List.flatten(shards)
  end

  @doc "True if any shards have state `:ready`"
  @spec is_any_shard_ready?(:ets.tab()) :: boolean
  def is_any_shard_ready?(table) do
    spec =
      Ex2ms.fun do
        {_, state} when state == :ready -> state
      end

    # Will be true if something matching the spec was found
    :ets.select(table, spec, 1) != :"$end_of_table"
  end

  @doc "Adds a shard to the list with state `:starting`"
  @spec add_shard(:ets.tab(), ShardInfo.t()) :: ShardInfo.t()
  def add_shard(table, %ShardInfo{} = shard) do
    :ets.insert(table, {shard, :starting})
    shard
  end

  @doc "Updates a shard's state to `:ready`"
  @spec update_shard_ready(:ets.tab(), ShardInfo.t()) :: ShardInfo.t()
  def update_shard_ready(table, %ShardInfo{} = shard) do
    :ets.insert(table, {shard, :ready})
    shard
  end
end
