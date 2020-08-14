defmodule Mobius.Shard.Ratelimiter.SelfRefillTest do
  use ExUnit.Case

  import Mobius.Fixtures

  alias Mobius.Shard.Ratelimiter.SelfRefill

  setup do
    [server: start_supervised!({SelfRefill, []})]
  end

  test "allows burst", %{server: server} do
    bucket = random_hex(8)

    before = System.monotonic_time(:millisecond)

    for _ <- 1..5 do
      assert :ok == SelfRefill.request_access(server, {bucket, 1000, 5})
    end

    assert System.monotonic_time(:millisecond) - before < 200
  end

  test "returns :ratelimited when out of tokens", %{server: server} do
    bucket = random_hex(8)

    assert :ok == SelfRefill.request_access(server, {bucket, 1000, 1})
    assert :ratelimited == SelfRefill.request_access(server, {bucket, 1000, 1})
  end

  test "refills after the delay", %{server: server} do
    bucket = random_hex(8)
    delay = 100

    assert :ok == SelfRefill.request_access(server, {bucket, delay, 1})
    assert :ratelimited == SelfRefill.request_access(server, {bucket, delay, 1})
    # Compensate for the time it takes to communicate with the server
    Process.sleep(delay + 10)
    assert :ok == SelfRefill.request_access(server, {bucket, delay, 1})
  end
end
