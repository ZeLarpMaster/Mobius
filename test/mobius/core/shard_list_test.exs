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

  describe "is_any_shard_ready?/1" do
    test "returns false if no shard is ready", ctx do
      assert false == ShardList.is_any_shard_ready?(ctx.table),
             "shards: #{inspect(:ets.tab2list(ctx.table))}"
    end

    test "returns true if one or more shards are ready", ctx do
      ShardList.update_shard_ready(ctx.table, hd(ctx.shards))

      assert true == ShardList.is_any_shard_ready?(ctx.table)
    end
  end
end
