defmodule Mobius.Models.ChannelTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.Models.Utils
  import Mobius.TestUtils

  alias Mobius.Models.Channel
  alias Mobius.Models.PermissionsOverwrite
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Channel.parse("string")
      assert nil == Channel.parse(42)
      assert nil == Channel.parse(true)
      assert nil == Channel.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Channel.parse()
      |> assert_field(:id, nil)
      |> assert_field(:type, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:position, nil)
      |> assert_field(:permission_overwrites, nil)
      |> assert_field(:name, nil)
      |> assert_field(:topic, nil)
      |> assert_field(:nsfw, nil)
      |> assert_field(:last_message_id, nil)
      |> assert_field(:bitrate, nil)
      |> assert_field(:user_limit, nil)
      |> assert_field(:rate_limit_per_user, nil)
      |> assert_field(:recipients, nil)
      |> assert_field(:icon, nil)
      |> assert_field(:owner_id, nil)
      |> assert_field(:application_id, nil)
      |> assert_field(:parent_id, nil)
      |> assert_field(:last_pin_timestamp, nil)
      |> assert_field(:rtc_region, nil)
      |> assert_field(:video_quality_mode, nil)
    end

    test "parses all fields as expected" do
      map = channel()

      map
      |> Channel.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:type, :guild_text)
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:position, map["position"])
      |> assert_field(:permission_overwrites, parse_overwrites(map["permission_overwrites"]))
      |> assert_field(:name, map["name"])
      |> assert_field(:topic, map["topic"])
      |> assert_field(:nsfw, map["nsfw"])
      |> assert_field(:last_message_id, Snowflake.parse(map["last_message_id"]))
      |> assert_field(:bitrate, map["bitrate"])
      |> assert_field(:user_limit, map["user_limit"])
      |> assert_field(:rate_limit_per_user, map["rate_limit_per_user"])
      |> assert_field(:recipients, parse_list(map["recipients"], &User.parse/1))
      |> assert_field(:icon, map["icon"])
      |> assert_field(:owner_id, Snowflake.parse(map["owner_id"]))
      |> assert_field(:application_id, Snowflake.parse(map["application_id"]))
      |> assert_field(:parent_id, Snowflake.parse(map["parent_id"]))
      |> assert_field(:last_pin_timestamp, Timestamp.parse(map["last_pin_timestamp"]))
      |> assert_field(:rtc_region, map["rtc_region"])
      |> assert_field(:video_quality_mode, :auto)
    end
  end

  defp parse_overwrites(overwrites), do: parse_list(overwrites, &PermissionsOverwrite.parse/1)
end
