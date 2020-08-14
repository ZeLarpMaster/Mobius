defmodule Mobius.Samples.Other do
  @moduledoc false

  @spec iso8601 :: String.t()
  def iso8601, do: DateTime.to_iso8601(DateTime.utc_now())
end
