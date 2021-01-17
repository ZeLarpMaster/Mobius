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

  alias Mobius.Models.Utils

  @type t :: pos_integer()

  @discord_epoch 1_420_070_400_000

  @spec parse(any) :: t() | nil
  def parse(value), do: Utils.parse_integer(value)

  @spec to_timestamp(t()) :: integer
  def to_timestamp(snowflake), do: (snowflake >>> 22) + @discord_epoch

  @spec from_timestamp(integer) :: t()
  def from_timestamp(timestamp_ms), do: (timestamp_ms - @discord_epoch) <<< 22

  @spec to_datetime(t()) :: DateTime.t()
  def to_datetime(snowflake) do
    snowflake
    |> to_timestamp()
    |> DateTime.from_unix!(:millisecond)
  end
end
