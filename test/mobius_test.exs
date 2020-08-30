defmodule MobiusTest do
  use ExUnit.Case
  doctest Mobius

  test "greets the world" do
    assert Mobius.hello() == :world
  end
end
