defmodule Mobius.ETSShelfTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.ETSShelf, as: Shelf

  setup :create_shelf

  setup do
    [table: :"test_table_#{random_hex(8)}"]
  end

  test "create_table/3 returns {:error, :ets_error} if table already exists", ctx do
    table = :ets.new(ctx.table, [:named_table])
    assert {:error, :ets_error} == Shelf.create_table(ctx.shelf, table, [])
  end

  test "create_table/3", ctx do
    pid = self()

    task =
      Task.async(fn ->
        Shelf.create_table(ctx.shelf, ctx.table, [])
        send(pid, :ready)
        Process.sleep(:infinity)
      end)

    assert_receive :ready

    # Table is owned by the task
    assert {:error, :ets_error} == Shelf.create_table(ctx.shelf, ctx.table, [])
    Task.shutdown(task)

    # Table went back to the shelf
    assert :ok == Shelf.create_table(ctx.shelf, ctx.table, [])

    true = :ets.insert(ctx.table, {123, :my_thing})
  end
end
