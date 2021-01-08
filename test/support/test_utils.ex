defmodule Mobius.TestUtils do
  @moduledoc false

  alias Mobius.Rest.Client

  @doc """
  Returns runtime of a function call in milliseconds

  ## Examples

      iex> function_time(Process.sleep(50)) in 45..55
      true
  """
  @spec function_time(any) :: Macro.output()
  defmacro function_time(function) do
    quote do
      fn -> unquote(function) end
      |> :timer.tc()
      |> elem(0)
      |> :erlang.convert_time_unit(:microsecond, :millisecond)
    end
  end

  @doc "Mocks the /gateway/bot request"
  @spec mock_gateway_bot(integer, integer) :: any
  def mock_gateway_bot(remaining \\ 1000, reset_after \\ 0) do
    app_info = %{
      "shards" => 1,
      "url" => "wss://gateway.discord.gg",
      "session_start_limit" => %{"remaining" => remaining, "reset_after" => reset_after}
    }

    url = Client.base_url() <> "/gateway/bot"
    Tesla.Mock.mock_global(fn %{url: ^url, method: :get} -> Mobius.Fixtures.json(app_info) end)
  end
end
