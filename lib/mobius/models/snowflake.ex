defmodule Mobius.Models.Snowflake do
  @moduledoc """
  Provides functions for working with snowflakes

  Snowflakes are integers, but they also come with some expectation in their form
  since they are effectively a timestamp which means snowflakes near each other in time
  will also be near each other as numbers.
  Therefore specifying a type as `t:t/0` gives more information about the value than an integer

  Related Discord documentation: https://discord.com/developers/docs/reference#snowflakes
  """

  import Bitwise

  alias Mobius.Model

  @behaviour Mobius.Model

  @type t :: pos_integer()

  @discord_epoch 1_420_070_400_000

  @doc """
  Parses a snowflake string into its integer representation

  Returns nil if the value isn't a string or isn't only a number
  """
  @impl true
  @spec parse(any) :: t() | nil
  def parse(value), do: Model.parse_integer(value)

  @doc """
  Returns the timestamp part (in milliseconds) of the snowflake

  ## Examples

      iex> to_timestamp(801609672695611394)
      1611189039158
      iex> to_timestamp(801609665888256071)
      1611189037535
  """
  @spec to_timestamp(t()) :: integer
  def to_timestamp(snowflake), do: (snowflake >>> 22) + @discord_epoch

  @doc """
  Returns a snowflake from a timestamp in milliseconds

  The snowflake has zeroes for the non-timestamp section.
  This means generated snowflakes will always be smaller
  than any snowflake made at that time.

  Mostly useful for filtering things by creation time.
  For example to filter messages by when they were sent,
  you can create snowflakes with the timestamp and compare the snowflakes together.

  ## Examples

      iex> from_timestamp(1611189039158)
      801609672694956032
      iex> to_timestamp(from_timestamp(1611189039158))
      1611189039158
  """
  @spec from_timestamp(integer) :: t()
  def from_timestamp(timestamp_ms), do: (timestamp_ms - @discord_epoch) <<< 22

  @doc """
  Returns a `t:DateTime.t/0` from a snowflake

  ## Examples

      iex> to_datetime(801609672695611394)
      ~U[2021-01-21 00:30:39.158Z]
  """
  @spec to_datetime(t()) :: DateTime.t()
  def to_datetime(snowflake) do
    snowflake
    |> to_timestamp()
    |> DateTime.from_unix!(:millisecond)
  end
end
