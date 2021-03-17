defmodule Mobius.Actions.UserTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators

  alias Mobius.Actions.User

  setup :reset_services
  setup :stub_socket
  setup :get_shard
  setup :handshake_shard

  describe "get_cached_user/1" do
    test "returns nil if not cached" do
      User.get_cached_user(random_snowflake())
    end

    test "returns the user if cached" do
      cached = user()
      send_payload(op: :dispatch, type: "USER_UPDATE", data: cached)

      Process.sleep(50)

      assert cached == User.get_cached_user(cached["id"])
    end
  end
end
