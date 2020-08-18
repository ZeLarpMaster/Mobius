defmodule Mobius.Utils do
  @moduledoc "A module of functions that can be generally useful to have access to"

  # Used to make the tests easily deterministic
  @disable_randomness Mix.env() == :test

  @doc """
  Converts bitflags into a MapSet of flag values

  Values from the list are included starting from the least significant bit.
  Parsing is stopped and the current result is returned when the list of things is exhausted.

  This function is the inverse of `create_bitflags/2`

  ## Examples

      iex> Mobius.Utils.parse_bitflags(0b01, [:a, :b])
      #MapSet<[:a]>

      iex> Mobius.Utils.parse_bitflags(0b1011, [0, 1, 2, 3])
      #MapSet<[0, 1, 3]>

      iex> Mobius.Utils.parse_bitflags(0b1111, [0, 1, 2])
      #MapSet<[0, 1, 2]>

      iex> Mobius.Utils.parse_bitflags(0, [[], %{}, "hi"])
      #MapSet<[]>

      iex> Mobius.Utils.parse_bitflags(0b11111111, [])
      #MapSet<[]>

      iex> flags = [:a, :b, :c, :d]
      iex> Mobius.Utils.parse_bitflags(0b1010, flags) |> Mobius.Utils.create_bitflags(flags)
      0b1010
  """
  @spec parse_bitflags(integer, [arg | nil], MapSet.t(arg)) :: MapSet.t(arg) when arg: var
  def parse_bitflags(num, flags, out \\ MapSet.new())
  def parse_bitflags(_num, [], out), do: out
  def parse_bitflags(0, _flags, out), do: out

  def parse_bitflags(num, [flag | flags], out) when is_integer(num) do
    import Bitwise
    out = if (num &&& 1) == 1 and flag != nil, do: MapSet.put(out, flag), else: out
    parse_bitflags(num >>> 1, flags, out)
  end

  @doc """
  Converts a list of flags into an integer of bitflags

  Foreach flag, if it can be found in the input, its associated bit will be 1 in the result.
  Starting from the least significant bit.

  This function is the inverse of `parse_bitflags/2`

  ## Examples

      iex> Mobius.Utils.create_bitflags(MapSet.new([:a, :b]), [:a, :b])
      0b11

      iex> Mobius.Utils.create_bitflags(MapSet.new([:b]), [:a, :b])
      0b10

      iex> Mobius.Utils.create_bitflags(MapSet.new([]), [:a, :b])
      0

      iex> Mobius.Utils.create_bitflags(MapSet.new([:a, :b]), [])
      0

      iex> flags = [:a, :b, :c, :d]
      iex> Mobius.Utils.parse_bitflags(0b1010, flags) |> Mobius.Utils.create_bitflags(flags)
      0b1010
  """
  @spec create_bitflags(MapSet.t(arg), list(arg)) :: integer when arg: var
  def create_bitflags(input, flags) when is_list(flags) do
    import Bitwise

    flags
    |> Stream.with_index()
    |> Stream.map(fn {flag, index} -> {flag, 1 <<< index} end)
    |> Stream.filter(fn {flag, _index} -> flag in input end)
    |> Stream.map(fn {_flag, index} -> index end)
    |> Enum.reduce(0, &Bitwise.bor/2)
  end

  @doc """
  Returns an url-safe base64 string of the given length

  The given length must be divisible by 4
  """
  @spec random_string(integer) :: String.t()
  # TODO: Make tests better so this isn't needed
  if @disable_randomness do
    def random_string(_length) do
      "a random string"
    end
  else
    def random_string(length) when rem(length, 4) == 0 do
      :crypto.strong_rand_bytes(div(length, 4) * 3)
      |> Base.url_encode64()
    end
  end
end
