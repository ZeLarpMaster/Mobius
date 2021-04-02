defmodule Mobius.Models.Timestamp do
  @moduledoc false

  @doc """
  Parse an ISO8601 datetime into a `t:DateTime.t()` or return nil if it was invalid

  ## Examples

      iex> parse("2021-01-16T00:26:15Z")
      ~U[2021-01-16 00:26:15Z]
      iex> parse("Something invalid")
      nil
      iex> parse(:not_a_string)
      nil
      iex> parse(42)
      nil
      iex> parse(%{})
      nil
  """
  @spec parse(String.t()) :: DateTime.t() | nil
  def parse(stamp) when is_binary(stamp) do
    case DateTime.from_iso8601(stamp) do
      {:error, _} -> nil
      {:ok, datetime, _offset} -> datetime
    end
  end

  def parse(_), do: nil

  @doc """
  Parses a unix timestamp into a `t:DateTime.t()` or return nil if it was invalid

  ## Examples

      iex> parse_unix(1615950426)
      ~U[2021-03-17 03:07:06Z]
      iex> parse_unix("invalid")
      nil
      iex> parse_unix(%{})
      nil
      iex> parse_unix("123456789")
      nil
  """
  def parse_unix(stamp) when is_integer(stamp) do
    case DateTime.from_unix(stamp, :second) do
      {:error, _} -> nil
      {:ok, datetime} -> datetime
    end
  end

  def parse_unix(_), do: nil
end
