defmodule Mobius.Services.ModelCacheTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Services.ModelCache

  setup do: ModelCache.clear()

  describe "user cache" do
    test "caches on ready" do
      cached = user()
      ModelCache.cache_event(:ready, %{"user" => cached})

      assert cached == ModelCache.get(cached["id"], ModelCache.User)
    end

    test "caches on user update" do
      cached = user()
      ModelCache.cache_event(:user_update, cached)

      assert cached == ModelCache.get(cached["id"], ModelCache.User)
    end

    test "caches on member add" do
      cached = user()
      ModelCache.cache_event(:guild_member_add, %{"user" => cached})

      assert cached == ModelCache.get(cached["id"], ModelCache.User)
    end

    test "caches on guild create" do
      cached = user()
      ModelCache.cache_event(:guild_create, %{"members" => [%{"user" => cached}]})

      assert cached == ModelCache.get(cached["id"], ModelCache.User)
    end
  end

  describe "member cache" do
    test "caches on member add" do
      member_data = member()
      cached = Map.put(member_data, "guild_id", random_snowflake())
      ModelCache.cache_event(:guild_member_add, cached)

      assert member_data == ModelCache.get(member_key(cached), ModelCache.Member)
    end

    test "caches on member update if not cached" do
      member_data = member()
      cached = Map.put(member_data, "guild_id", random_snowflake())
      ModelCache.cache_event(:guild_member_update, cached)

      assert member_data == ModelCache.get(member_key(cached), ModelCache.Member)
    end

    test "updates the cache on member update if already cached" do
      member_data = member()
      original = Map.put(member_data, "guild_id", random_snowflake())
      new_member = member(user: user(id: original["user"]["id"]))
      cached = Map.put(new_member, "guild_id", original["guild_id"])

      ModelCache.cache_event(:guild_member_add, original)
      ModelCache.cache_event(:guild_member_update, cached)

      # Make sure we aren't incredibly unlucky otherwise the other assert makes no sense
      assert member_data != new_member
      assert new_member == ModelCache.get(member_key(cached), ModelCache.Member)
    end

    test "invalides on member remove" do
      cached = Map.put(member(), "guild_id", random_snowflake())
      ModelCache.cache_event(:guild_member_add, cached)
      ModelCache.cache_event(:guild_member_remove, cached)

      assert nil == ModelCache.get(member_key(cached), ModelCache.Member)
    end
  end

  describe "get/2" do
    test "returns the cached value if cached" do
      cached = user()
      ModelCache.cache_event(:ready, %{"user" => cached})

      assert cached == ModelCache.get(cached["id"], ModelCache.User)
    end

    test "returns nil if not cached" do
      assert nil == ModelCache.get(user()["id"], ModelCache.User)
    end
  end

  describe "list/1" do
    test "returns the cached values" do
      cached = [user(), user()]
      members = Enum.map(cached, fn user -> %{"user" => user} end)
      ModelCache.cache_event(:guild_create, %{"members" => members})

      assert_list_unordered(ModelCache.list(ModelCache.User), cached)
    end

    test "returns an empty list if nothing cached" do
      assert [] == Enum.to_list(ModelCache.list(ModelCache.User))
    end
  end

  defp member_key(%{"guild_id" => guild_id, "user" => %{"id" => id}}), do: {guild_id, id}
end
