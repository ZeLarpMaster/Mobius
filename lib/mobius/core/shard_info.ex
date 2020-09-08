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
  def from_count(count) when is_integer(count) and count > 0 do
    for num <- 0..(count - 1) do
      new(number: num, count: count)
    end
  end

  @spec to_list(t()) :: [integer]
  def to_list(%__MODULE__{} = info), do: [info.number, info.count]
end
