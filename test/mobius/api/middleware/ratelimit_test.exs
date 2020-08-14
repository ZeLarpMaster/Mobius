defmodule Mobius.Api.Middleware.RatelimitTest do
  use ExUnit.Case

  import Tesla.Mock
  import Mobius.Fixtures
  import Mobius.Assertions

  alias Mobius.Api.Middleware.Ratelimit

  setup do
    {:ok, pid} = Ratelimit.start_link([])
    [ratelimit_server: pid]
  end

  setup ctx do
    token = random_hex(8)
    middleware = [{Ratelimit, server: ctx.ratelimit_server}]
    [client: Tesla.client(middleware, Tesla.Mock), token: token]
  end

  test "doesn't wait when remaining > 0", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(2, 500, 0) end)

    assert_function_time(250, fn ->
      Tesla.get(ctx.client, url)
      Tesla.get(ctx.client, url)
    end)
  end

  test "waits until reset-after when remaining is 0", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(0, 500, 0) end)

    assert_function_time(500, 600, fn ->
      Tesla.get(ctx.client, url)
      Tesla.get(ctx.client, url)
    end)
  end

  test "waits until reset-after when 429 without global ratelimit", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(-1, 500, 0) end)

    assert_function_time(500, 600, fn ->
      Tesla.get(ctx.client, url)
      Tesla.get(ctx.client, url)
    end)
  end

  test "waits until reset-after when 429 with global ratelimit", ctx do
    url = "https://discord.com/api/v6/something"
    mock(fn %{url: ^url} -> response(0, 250, 500) end)

    assert_function_time(500, 600, fn ->
      Tesla.get(ctx.client, url)
      Tesla.get(ctx.client, url)
    end)
  end

  test "waits even if route is different when bucket is the same", ctx do
    mock(fn %{method: :get} -> response(0, 250, 0) end)

    assert_function_time(500, 600, fn ->
      # Tell the ratelimit about the 2 urls having the same bucket
      Tesla.get(ctx.client, "https://discord.com/api/v6/something")
      Tesla.get(ctx.client, "https://discord.com/api/v6/different")
      # Wait until the reset
      Process.sleep(250)
      # Tell the ratelimit about having used all the requests
      Tesla.get(ctx.client, "https://discord.com/api/v6/something")
      # This one needs to wait until the reset
      Tesla.get(ctx.client, "https://discord.com/api/v6/different")
    end)
  end

  defp response(remaining, delay, global_delay) do
    cond do
      global_delay > 0 ->
        {429, [{"retry-after", "#{global_delay}"}, {"x-ratelimit-global", "true"}],
         %{"retry_after" => global_delay, "global" => true}}

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
      {"x-ratelimit-bucket", "Bucket"}
    ]
  end
end
