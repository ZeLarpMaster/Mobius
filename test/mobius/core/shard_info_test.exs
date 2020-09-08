defmodule Mobius.Core.ShardInfoTest do
  use ExUnit.Case, async: true

  import Mobius.Core.ShardInfo

  test "from_count/1 generates a list of shard infos" do
    assert from_count(1) == [new(number: 0, count: 1)]

    list = from_count(3)
    assert list == [new(number: 0, count: 3), new(number: 1, count: 3), new(number: 2, count: 3)]
  end

  test "to_list/1 returns a list with the number and count" do
    assert to_list(new(number: 21, count: 42)) == [21, 42]
  end
end
