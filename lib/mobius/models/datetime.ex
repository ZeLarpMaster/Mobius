defmodule Mobius.Models.DateTime do
  @moduledoc false

  @doc """
  Parse an ISO8601 datetime into a `t:DateTime.t()` or return nil if it was invalid

  ## Examples

      iex> parse("2021-01-16T00:26:15Z")
      ~U[2021-01-16 00:26:15Z]

      iex> parse("Something invalid")
      nil
  """
  @spec parse(String.t()) :: DateTime.t() | nil
  def parse(stamp) do
    case DateTime.from_iso8601(stamp) do
      {:error, _} -> nil
      {:ok, datetime, _offset} -> datetime
    end
  end
end
