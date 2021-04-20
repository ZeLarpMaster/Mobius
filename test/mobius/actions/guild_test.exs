defmodule Mobius.Actions.GuildTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators

  alias Mobius.Actions.Guild

  setup :reset_services
  setup :stub_socket
  setup :get_shard
  setup :handshake_shard

  describe "get_cached_guild/1" do
    test "returns nil if not cached" do
      Guild.get_cached_guild(random_snowflake())
    end

    test "returns the guild if cached" do
      cached = guild()
      send_payload(op: :dispatch, type: "GUILD_CREATE", data: cached)

      # Give a bit of time for the cache to pick up the event
      Process.sleep(50)

      assert cached == Guild.get_cached_guild(cached["id"])
    end
  end
end
