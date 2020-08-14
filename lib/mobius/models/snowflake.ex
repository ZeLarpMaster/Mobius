defmodule Mobius.Models.Snowflake do
  @moduledoc """
  Provides functions for working with snowflakes

  While snowflakes are indeed just integers, they come with some expectations in their form
  So specifying a type as a `t:t/0` gives more information about the value than just `t:integer/0`
  """

  import Bitwise

  @type t :: pos_integer()

  @discord_epoch 1_420_070_400_000

  @spec string_to_snowflake(String.t()) :: t() | :invalid_input
  def string_to_snowflake(binary) when is_binary(binary) do
    with {integer, ""} <- Integer.parse(binary) do
      integer
    else
      {_, remainder} when is_binary(remainder) -> :invalid_input
      :error -> :invalid_input
    end
  end

  @spec snowflake_to_timestamp(t()) :: integer
  def snowflake_to_timestamp(snowflake) do
    (snowflake >>> 22) + @discord_epoch
  end

  @spec timestamp_to_snowflake(integer) :: t()
  def timestamp_to_snowflake(timestamp_ms) do
    (timestamp_ms - @discord_epoch) <<< 22
  end

  @spec snowflake_to_datetime(t()) :: DateTime.t()
  def snowflake_to_datetime(snowflake) do
    snowflake
    |> snowflake_to_timestamp()
    |> DateTime.from_unix!(:millisecond)
  end
end
