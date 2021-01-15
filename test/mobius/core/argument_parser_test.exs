defmodule Mobius.Core.ArgumentParserTest do
  use ExUnit.Case, async: true

  alias Mobius.Core.Command.ArgumentParser

  describe "when parsing strings" do
    test "should return the value" do
      assert ArgumentParser.parse(:string, "hello") == "hello"
    end
  end

  describe "when parsing integers" do
    test "should return :error for non-numeric values" do
      assert ArgumentParser.parse(:integer, "hello") == :error
    end

    test "should return :error for floats" do
      assert ArgumentParser.parse(:integer, "1.0") == :error
    end

    test "should return the parsed integer" do
      assert ArgumentParser.parse(:integer, "42") == 42
    end
  end
end
