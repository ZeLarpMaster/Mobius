defmodule Mobius.Services.RestRatelimiterTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Services.RestRatelimiter

  describe "wait_ratelimit/1" do
    test "doesn't wait for global if never updated"
    test "waits for global until the reset time"
    test "uses same limit for different routes with same bucket"
    test "doesn't wait when never seen the route"
    test "doesn't wait if route's bucket's limit has expired"
    test "doesn't wait if route's bucket's limit isn't exhausted"
    test "waits if route's bucket's limit is exhausted"
  end
end
