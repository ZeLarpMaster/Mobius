defmodule Mobius.Core.ShardInfo do
  @moduledoc false

  defstruct [:number, :count]

  @type t :: %__MODULE__{
          number: non_neg_integer,
          count: pos_integer
        }

  @spec new(keyword) :: t()
  def new(fields), do: struct!(__MODULE__, fields)

  @spec from_count(pos_integer) :: [t()]
  def from_count(count) do
    for num <- 0..(count - 1) do
      new(number: num, count: count)
    end
  end
end
