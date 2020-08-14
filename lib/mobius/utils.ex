defmodule Mobius.Utils do
  @moduledoc "A module of functions that can be generally useful to have access to"

  # Used to make the tests easily deterministic
  @disable_randomness Mix.env() == :test

  @doc """
  Returns an url-safe base64 string of the given length

  The given length must be divisible by 4
  """
  @spec random_string(integer) :: String.t()
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
