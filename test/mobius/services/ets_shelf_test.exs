defmodule Mobius.Services.ETSShelfTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Services.ETSShelf, as: Shelf

  setup do
    [table: :"test_table_#{random_hex(8)}"]
  end

  test "create_table/2 returns {:error, :ets_error} if table already exists", ctx do
    table = :ets.new(ctx.table, [:named_table])
    assert {:error, :ets_error} == Shelf.create_table(table, [])
  end

  test "create_table/2 gives the table after original owner dies", ctx do
    pid = self()

    task =
      Task.async(fn ->
        Shelf.create_table(ctx.table, [])
        send(pid, :ready)
        Process.sleep(:infinity)
      end)

    assert_receive :ready

    # Table is owned by the task
    assert {:error, :ets_error} == Shelf.create_table(ctx.table, [])
    Task.shutdown(task)

    # Table went back to the shelf
    assert :ok == Shelf.create_table(ctx.table, [])

    assert :ets.insert(ctx.table, {123, :my_thing})
  end
end
