defmodule Mobius.Rest.Middleware.RatelimitTest do
  use ExUnit.Case

  import Tesla.Mock
  import Mobius.Assertions

  alias Mobius.Rest.Middleware.Ratelimit

  setup do: [client: Tesla.client([{Ratelimit, []}], Tesla.Mock)]

  test "doesn't wait if route still has remaining calls", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(2, 50, 0) end)
    Tesla.get(ctx.client, url)

    assert_get_time(ctx.client, url, 0)
  end

  test "waits until reset-after if route is exhausted", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(0, 50, 0) end)
    Tesla.get(ctx.client, url)

    assert_get_time(ctx.client, url, 50)
  end

  test "waits until reset-after if ratelimit was exceeded", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(-1, 50, 0) end)
    Tesla.get(ctx.client, url)

    assert_get_time(ctx.client, url, 50)
  end

  test "waits until reset-after if global ratelimit was exceeded", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(0, 100, 50) end)
    Tesla.get(ctx.client, url)

    assert_get_time(ctx.client, url, 50)
  end

  test "waits even if route is different when bucket is the same", ctx do
    # This table is used to make the mock stateful
    table = :ets.new(:ratelimit_test, [:private, :set])

    mock(fn %{method: :get} ->
      [{:remaining, remaining}] = :ets.lookup(table, :remaining)
      response(remaining, 50, 0)
    end)

    # First 2 calls to associate both routes to the same bucket
    :ets.insert(table, {:remaining, 2})
    Tesla.get(ctx.client, "https://discord.com/api/v6/something")
    :ets.insert(table, {:remaining, 1})
    Tesla.get(ctx.client, "https://discord.com/api/v6/different")
    # Trigger the ratelimit on the bucket
    :ets.insert(table, {:remaining, 0})
    Tesla.get(ctx.client, "https://discord.com/api/v6/something")

    assert_get_time(ctx.client, "https://discord.com/api/v6/different", 50)
  end

  defp assert_get_time(client, url, expected_time) do
    client
    |> Tesla.get(url)
    |> function_time()
    |> assert_in_delta(expected_time, 10)
  end

  defp response(remaining, delay, global_delay) do
    cond do
      global_delay > 0 ->
        {429,
         [
           {"retry-after", "#{global_delay}"},
           {"x-ratelimit-global", "true"}
         ], %{"retry_after" => global_delay, "global" => true}}

      remaining < 0 ->
        {429, headers(0, delay), %{"retry_after" => delay, "global" => false}}

      true ->
        {204, headers(remaining, delay), nil}
    end
  end

  defp headers(remaining, delay) do
    [
      {"retry-after", "#{delay}"},
      {"x-ratelimit-limit", "5"},
      {"x-ratelimit-remaining", "#{remaining}"},
      {"x-ratelimit-reset", "#{System.system_time(:millisecond) + delay}"},
      {"x-ratelimit-reset-after", "#{delay}"},
      {"x-ratelimit-bucket", "test-bucket"}
    ]
  end
end
