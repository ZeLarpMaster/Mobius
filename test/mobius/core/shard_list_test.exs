defmodule Mobius.Core.ShardListTest do
  use ExUnit.Case

  alias Mobius.Core.ShardInfo
  alias Mobius.Core.ShardList

  setup do
    tab = :ets.new(:shard_list, ShardList.table_options())
    shards = ShardInfo.from_count(2)
    Enum.each(shards, &ShardList.add_shard(tab, &1))
    [table: tab, shards: shards]
  end

  describe "list_shards/1" do
    test "lists all added shards", ctx do
      assert ctx.shards == ShardList.list_shards(ctx.table)
    end

    test "includes ready shards", ctx do
      ShardList.update_shard_ready(ctx.table, List.first(ctx.shards))

      assert ctx.shards == ShardList.list_shards(ctx.table)
    end
  end

  describe "are_all_shards_ready?/1" do
    test "returns false if one or more shards aren't ready", ctx do
      assert false == ShardList.are_all_shards_ready?(ctx.table)
    end

    test "returns true if all shards are ready", ctx do
      Enum.each(ctx.shards, &ShardList.update_shard_ready(ctx.table, &1))

      assert true == ShardList.are_all_shards_ready?(ctx.table)
    end
  end
end
