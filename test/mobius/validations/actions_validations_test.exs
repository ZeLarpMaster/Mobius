defmodule Mobius.Validations.ActionValidationsTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.TestUtils

  alias Mobius.Validations.ActionValidations

  describe "string_length_validator/3" do
    setup do
      min = 2
      max = 4
      validator = ActionValidations.string_length_validator(min, max)

      [min: min, max: max, validator: validator]
    end

    test "returns an error when provided a non-string input", ctx do
      {:error, error} = ctx.validator.(:bar)

      assert error =~ "be a string"
    end

    test "returns an error when provided string length is outside allowed range", ctx do
      error_message = "contain between #{ctx.min} and #{ctx.max} characters"

      {:error, error} = ctx.validator.(random_text(ctx.min - 1))
      assert error =~ error_message

      {:error, error} = ctx.validator.(random_text(ctx.max + 1))
      assert error =~ error_message
    end

    test "returns :ok when provided string length is inside the allowed range", ctx do
      assert :ok = ctx.validator.(random_text(ctx.max - 1))
    end
  end

  describe "integer_range_validator/3" do
    setup do
      min = 2
      max = 4
      validator = ActionValidations.integer_range_validator(min, max)

      [min: min, max: max, validator: validator]
    end

    test "returns an error when provided a non-integer input", ctx do
      {:error, error} = ctx.validator.(:bar)

      assert error =~ "be an integer"
    end

    test "returns an error when provided integer is outside allowed range", ctx do
      error_message = "be between #{ctx.min} and #{ctx.max}"

      {:error, error} = ctx.validator.(ctx.min - 1)
      assert error =~ error_message

      {:error, error} = ctx.validator.(ctx.max + 1)
      assert error =~ error_message
    end

    test "returns :ok when provided integer is inside the allowed range", ctx do
      assert :ok = ctx.validator.(ctx.max - 1)
    end
  end

  describe "validate_params/2" do
    test "returns all errors returned by the validators" do
      validator1 = fn _ -> {:error, "error 1"} end
      validator2 = fn _ -> {:error, "error 2"} end

      {:error, errors} =
        ActionValidations.validate_params(%{foo: :foo, bar: :bar}, [
          {:foo, validator1},
          {:bar, validator2}
        ])

      assert_list_unordered(errors, ["Expected bar to error 2", "Expected foo to error 1"])
    end

    test "returns :ok if no validator returns an error" do
      assert :ok = ActionValidations.validate_params(%{}, [])
    end
  end
end
