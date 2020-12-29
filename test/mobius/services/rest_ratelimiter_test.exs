defmodule Mobius.Services.RestRatelimiterTest do
  use ExUnit.Case

  import Mobius.Assertions

  alias Mobius.Services.RestRatelimiter

  describe "wait_ratelimit/1" do
    test "doesn't wait for global if never updated" do
      assert_wait_time("global", 5)
    end

    test "waits for global until the reset time" do
      RestRatelimiter.update_global_ratelimit(50)
      assert_wait_time("global", 50)
    end

    test "uses same limit for different routes with same bucket" do
      bucket = "test-bucket"
      RestRatelimiter.update_route_ratelimit(:route1, bucket, 3, 500)
      RestRatelimiter.update_route_ratelimit(:route2, bucket, 2, 500)
      RestRatelimiter.update_route_ratelimit(:route1, bucket, 0, 50)
      assert_wait_time(:route2, 50)
    end

    test "doesn't wait when never seen the route" do
      assert_wait_time(:route, 5)
    end

    test "doesn't wait if route's bucket's limit has expired" do
      RestRatelimiter.update_route_ratelimit(:route, "test-bucket", 0, 50)
      Process.sleep(50)
      assert_wait_time(:route, 5)
    end

    test "doesn't wait if route's bucket's limit isn't exhausted" do
      RestRatelimiter.update_route_ratelimit(:route, "test-bucket", 1, 50)
      assert_wait_time(:route, 5)
    end

    test "waits if route's bucket's limit is exhausted" do
      RestRatelimiter.update_route_ratelimit(:route, "test-bucket", 0, 50)
      assert_wait_time(:route, 50)
    end
  end

  defp assert_wait_time(route, expected_time) do
    route
    |> RestRatelimiter.wait_ratelimit()
    |> function_time()
    |> assert_in_delta(expected_time, 10)
  end
end
