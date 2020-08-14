defmodule Mobius.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  @spec assert_function_time(non_neg_integer(), non_neg_integer(), (() -> any)) :: true
  def assert_function_time(min_time \\ 0, max_time, func) do
    time =
      func
      |> :timer.tc()
      |> elem(0)
      |> Kernel.div(1000)

    assert min_time <= time
    assert time <= max_time
  end
end
