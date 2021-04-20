defmodule Mobius.Actions.UtilsTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Actions.Utils

  describe "string_length_validator/3" do
    setup do
      min = 2
      max = 4
      validator = Utils.string_length_validator(:foo, min, max)

      [min: min, max: max, validator: validator]
    end

    test "returns an error when provided a non-string input", ctx do
      {:error, error} = ctx.validator.(%{foo: :bar})

      assert error =~ "Expected foo to be a string"
    end

    test "returns an error when provided string length is outside allowed range", ctx do
      error_message = "Expected foo to contain between #{ctx.min} and #{ctx.max} characters"

      {:error, error} = ctx.validator.(%{foo: random_text(ctx.min - 1)})
      assert error =~ error_message

      {:error, error} = ctx.validator.(%{foo: random_text(ctx.max + 1)})
      assert error =~ error_message
    end

    test "returns :ok when provided string length is inside the allowed range", ctx do
      assert :ok = ctx.validator.(%{foo: random_text(ctx.max - 1)})
    end

    test "returns :ok when the key is not in the provided input", ctx do
      assert :ok = ctx.validator.(%{})
    end
  end

  describe "integer_range_validator/3" do
    setup do
      min = 2
      max = 4
      validator = Utils.integer_range_validator(:foo, min, max)

      [min: min, max: max, validator: validator]
    end

    test "returns an error when provided a non-integer input", ctx do
      {:error, error} = ctx.validator.(%{foo: :bar})

      assert error =~ "Expected foo to be an integer"
    end

    test "returns an error when provided integer is outside allowed range", ctx do
      error_message = "Expected foo to be between #{ctx.min} and #{ctx.max}"

      {:error, error} = ctx.validator.(%{foo: ctx.min - 1})
      assert error =~ error_message

      {:error, error} = ctx.validator.(%{foo: ctx.max + 1})
      assert error =~ error_message
    end

    test "returns :ok when provided integer is inside the allowed range", ctx do
      assert :ok = ctx.validator.(%{foo: ctx.max - 1})
    end

    test "returns :ok when the key is not in the provided input", ctx do
      assert :ok = ctx.validator.(%{})
    end
  end

  describe "validate_params/2" do
    test "returns all errors returned by the validators" do
      validator1 = fn _ -> {:error, "error 1"} end
      validator2 = fn _ -> {:error, "error 2"} end

      {:error, errors} = Utils.validate_params(%{}, [validator1, validator2])

      assert_list_unordered(errors, ["error 1", "error 2"])
    end

    test "returns :ok if no validator returns an error" do
      assert :ok = Utils.validate_params(%{}, [])
    end
  end
end
