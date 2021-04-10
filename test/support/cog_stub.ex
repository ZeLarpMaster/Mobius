defmodule Mobius.Stubs.Cog do
  @moduledoc false

  use Mobius.Cog

  alias Mobius.Models.Message

  listen :message_create, %Message{content: content} do
    send_to_test(content)
  end

  command "nothing" do
    send_to_test(:nothing)
  end

  command "send", context do
    send_to_test(context)
  end

  command "reply", value: :integer do
    send_to_test(value + 10)
  end

  command "reply", message: :string do
    send_to_test(message)
  end

  command "reply", num1: :integer, num2: :integer do
    send_to_test(num1 + num2)
  end

  command "everything", context, value: :string do
    send_to_test({:everything, context, value})
  end

  command "everything", value: :integer do
    send_to_test({:unexpected_everything, value})
  end

  defp send_to_test(message) do
    send(:cog_test_process, message)
  end
end
