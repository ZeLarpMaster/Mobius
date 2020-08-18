defmodule Mobius.Parsers.UtilsTest do
  use ExUnit.Case, async: true

  alias Mobius.Parsers.Utils

  test "parse_flags/2" do
    flags = [:flag1, :flag2, :flag4]

    assert MapSet.new() == Utils.parse_flags(0, flags)
    assert MapSet.new([:flag1]) == Utils.parse_flags(1, flags)
    assert MapSet.new([:flag4]) == Utils.parse_flags(4, flags)
    assert MapSet.new([:flag4, :flag1]) == Utils.parse_flags(5, flags)
    assert MapSet.new([:flag4, :flag2, :flag1]) == Utils.parse_flags(7, flags)
    assert MapSet.new() == Utils.parse_flags(8, flags)
    assert MapSet.new([:flag1]) == Utils.parse_flags(9, flags)
  end

  test "parse_iso8601/2" do
    try do
      Utils.parse_iso8601("2020-07-11T12:00:30", "v")
    catch
      {:invalid_value, _, "v"} -> :ok
    else
      _ -> flunk("Expected it to throw a value")
    end

    datetime = Utils.parse_iso8601("2020-07-11T12:00:30+00:00", "v")
    assert datetime.year == 2020
    assert datetime.month == 7
    assert datetime.day == 11
    assert datetime.hour == 12
    assert datetime.minute == 0
    assert datetime.second == 30
  end

  test "parse_snowflake/2" do
    assert 123 == Utils.parse_snowflake("123", nil)

    try do
      Utils.parse_snowflake("abc", "path")
    catch
      {:invalid_value, "abc", "path"} -> :ok
    else
      _ -> flunk("Expected it to throw a value")
    end
  end

  test "parse/3 returns {:error, :invalid_input} with invalid input type" do
    assert {:error, :invalid_input} == Utils.parse([], :hello, nil)
  end
end
