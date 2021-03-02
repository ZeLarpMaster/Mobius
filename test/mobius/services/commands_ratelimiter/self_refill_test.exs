defmodule Mobius.Services.CommandsRatelimiter.SelfRefillTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Services.CommandsRatelimiter.SelfRefill

  setup do
    # Manually start the service because it won't be started during tests
    start_supervised!({SelfRefill, []})
    # Generate a random bucket name so they don't overlap during tests
    [bucket: random_hex(16)]
  end

  describe "request_access/1" do
    test "returns :ok for the first `max_tokens` requests", ctx do
      assert :ok == SelfRefill.request_access({ctx.bucket, 500, 3})
      assert :ok == SelfRefill.request_access({ctx.bucket, 500, 3})
      assert :ok == SelfRefill.request_access({ctx.bucket, 500, 3})
    end

    test "returns :ratelimited after `max_tokens` requests", ctx do
      SelfRefill.request_access({ctx.bucket, 500, 3})
      SelfRefill.request_access({ctx.bucket, 500, 3})
      SelfRefill.request_access({ctx.bucket, 500, 3})

      assert :ratelimited == SelfRefill.request_access({ctx.bucket, 500, 3})
    end

    test "returns :ok `delay` ms after the first request", ctx do
      SelfRefill.request_access({ctx.bucket, 50, 1})
      :ratelimited = SelfRefill.request_access({ctx.bucket, 50, 1})
      Process.sleep(50)
      assert :ok == SelfRefill.request_access({ctx.bucket, 50, 1})
    end

    test "buckets are separate", ctx do
      assert :ok == SelfRefill.request_access({ctx.bucket <> ":a", 500, 1})
      assert :ok == SelfRefill.request_access({ctx.bucket <> ":b", 500, 1})
    end
  end
end
