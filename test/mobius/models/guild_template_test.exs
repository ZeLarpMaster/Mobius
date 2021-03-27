defmodule Mobius.Models.GuildTemplateTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Guild
  alias Mobius.Models.GuildTemplate
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == GuildTemplate.parse("string")
      assert nil == GuildTemplate.parse(42)
      assert nil == GuildTemplate.parse(true)
      assert nil == GuildTemplate.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> GuildTemplate.parse()
      |> assert_field(:code, nil)
      |> assert_field(:name, nil)
      |> assert_field(:description, nil)
      |> assert_field(:usage_count, nil)
      |> assert_field(:creator_id, nil)
      |> assert_field(:creator, nil)
      |> assert_field(:created_at, nil)
      |> assert_field(:updated_at, nil)
      |> assert_field(:source_guild_id, nil)
      |> assert_field(:serialized_source_guild, nil)
      |> assert_field(:is_dirty, nil)
    end

    test "parses all fields as expected" do
      map = %{
        "code" => random_hex(8),
        "name" => random_hex(16),
        "description" => random_hex(32),
        "usage_count" => :rand.uniform(256),
        "creator_id" => random_snowflake(),
        "creator" => user(),
        "created_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "updated_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "source_guild_id" => random_snowflake(),
        "serialized_source_guild" => guild(),
        "is_dirty" => false
      }

      map
      |> GuildTemplate.parse()
      |> assert_field(:code, map["code"])
      |> assert_field(:name, map["name"])
      |> assert_field(:description, map["description"])
      |> assert_field(:usage_count, map["usage_count"])
      |> assert_field(:creator_id, Snowflake.parse(map["creator_id"]))
      |> assert_field(:creator, User.parse(map["creator"]))
      |> assert_field(:created_at, Timestamp.parse(map["created_at"]))
      |> assert_field(:updated_at, Timestamp.parse(map["updated_at"]))
      |> assert_field(:source_guild_id, Snowflake.parse(map["source_guild_id"]))
      |> assert_field(:serialized_source_guild, Guild.parse(map["serialized_source_guild"]))
      |> assert_field(:is_dirty, map["is_dirty"])
    end
  end
end
