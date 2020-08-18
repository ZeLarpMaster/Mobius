defmodule Mobius.Utils do
  @moduledoc "A module of functions that can be generally useful to have access to"

  # Used to make the tests easily deterministic
  @disable_randomness Mix.env() == :test

  @doc """
  Converts bitflags into a MapSet of values

  The ordering of the list starts at the first element for the least significant bit.
  Parsing is stopped and the current result is returned when the list of things is exhausted.

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
