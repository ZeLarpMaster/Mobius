defmodule Mobius.Core.ShardBuckets do
  @moduledoc false

  @type t :: %{optional(String.t()) => non_neg_integer}

  @spec new :: t()
  def new, do: %{}

  @doc """
  Acquire one token from the given bucket

  Returns `{:ok, new_buckets}` if there was a token left in the bucket.
  Returns `{:ratelimited, new_buckets}` otherwise.

  ## Examples

      iex> {:ok, buckets} = acquire(new(), "abc", 2)
      iex> {:ok, buckets} = acquire(buckets, "abc", 2)
      iex> {:ratelimited, _} = acquire(buckets, "abc", 2)
  """
  @spec acquire(t(), String.t(), non_neg_integer) :: {:ok | :ratelimited, t()}
  def acquire(buckets, name, max_tokens) do
    Map.get_and_update(buckets, name, fn
      nil -> {:ok, max_tokens - 1}
      0 -> {:ratelimited, 0}
      tokens -> {:ok, tokens - 1}
    end)
  end

  @doc """
  Release one token to be acquired again

  Returns the new data structure

  ## Examples

      iex> {:ok, buckets} = acquire(new(), "abc", 1)
      iex> {:ratelimited, buckets} = acquire(buckets, "abc", 1)
      iex> buckets = release(buckets, "abc")
      iex> {:ok, _} = acquire(buckets, "abc", 1)
  """
  @spec release(t(), String.t()) :: t()
  def release(buckets, name) do
    Map.update!(buckets, name, fn tokens -> tokens + 1 end)
  end
end
