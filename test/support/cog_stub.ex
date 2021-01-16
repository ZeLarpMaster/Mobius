defmodule Mobius.Stubs.Cog do
  @moduledoc false

  use Mobius.Cog

  listen :message_create, %{"content" => content} do
    send_to_test(content)
  end

  command "reply", message: :string do
    send_to_test(message)
  end

  command "add", num1: :integer, num2: :integer do
    send_to_test(num1 + num2)
  end

  defp send_to_test(message) do
    :cog_test_process
    |> Process.whereis()
    |> send(message)
  end
end
