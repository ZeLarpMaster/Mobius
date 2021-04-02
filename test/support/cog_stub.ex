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

  command "reply", message: :string do
    send_to_test(message)
  end

  command "add", num1: :integer, num2: :integer do
    send_to_test(num1 + num2)
  end

  command "everything", context, value: :integer do
    send_to_test({:everything, context, value})
  end

  defp send_to_test(message) do
    send(:cog_test_process, message)
  end
end
