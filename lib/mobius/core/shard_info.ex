defmodule Mobius.Core.ShardInfo do
  @moduledoc false

  defstruct [:number, :count]

  @type t :: %__MODULE__{
          number: non_neg_integer,
          count: pos_integer
        }

  @spec new(keyword) :: t()
  def new(fields), do: struct!(__MODULE__, fields)

  @doc """
  Generate a list of ShardInfo structs going from 0 to n-1

      iex> from_count(0)
      ** (FunctionClauseError) no function clause matching in Mobius.Core.ShardInfo.from_count/1
      iex> from_count(1) == [new(number: 0, count: 1)]
      true
      iex> from_count(2) == [new(number: 0, count: 2), new(number: 1, count: 2)]
      true
  """
  @spec from_count(pos_integer) :: [t()]
  def from_count(count) when is_integer(count) and count > 0 do
    for num <- 0..(count - 1) do
      new(number: num, count: count)
    end
  end

  @doc """
  Convert a ShardInfo struct into a list

      iex> to_list(new(number: 3, count: 10))
      [3, 10]
  """
  @spec to_list(t()) :: [integer]
  def to_list(%__MODULE__{} = info), do: [info.number, info.count]

  @doc """
  Convert a tuple list into a ShardInfo struct

      iex> info = new(number: 3, count: 10)
      iex> info == from_list(to_list(info))
      true
      iex> info == from_list([3, 10])
      true
  """
  @spec from_list([integer]) :: t()
  def from_list([num, count]), do: new(number: num, count: count)

  defimpl Inspect do
    import Inspect.Algebra

    @spec inspect(ShardInfo.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
    def inspect(value, opts) do
      concat(["#ShardInfo<", to_doc(value.number, opts), "/", to_doc(value.count, opts), ">"])
    end
  end
end
