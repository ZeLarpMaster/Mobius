defmodule Mobius.Core.EventTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures
  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Core.Event
  alias Mobius.Core.ShardInfo
  alias Mobius.Model
  alias Mobius.Models

  describe "parse_name/1" do
    test "returns atom event name for string event name" do
      assert :guild_create == Event.parse_name("GUILD_CREATE")
    end

    test "returns nil for non-event string" do
      assert nil == Event.parse_name("THIS IS NOT AN EVENT")
    end

    test "returns nil for non-strings" do
      assert nil == Event.parse_name(true)
      assert nil == Event.parse_name(42)
      assert nil == Event.parse_name(:channel_create)
      assert nil == Event.parse_name(%{})
      assert nil == Event.parse_name(["stuff"])
      assert nil == Event.parse_name({:ok, "hello"})
    end
  end

  describe "is_event_name?/1" do
    test "returns true for a valid event name" do
      assert Event.is_event_name?(:message_create)
    end

    test "returns false for non-atoms" do
      assert not Event.is_event_name?(true)
      assert not Event.is_event_name?(32)
      assert not Event.is_event_name?("MESSAGE_CREATE")
      assert not Event.is_event_name?(%{})
      assert not Event.is_event_name?(["stuff"])
      assert not Event.is_event_name?({:ok, "hello"})
    end

    test "returns false for invalid event name atom" do
      assert not Event.is_event_name?(:this_isnt_an_event)
    end
  end

  describe "parse_data/2" do
    test "raises a FunctionClauseError if the event name is invalid" do
      assert_raise FunctionClauseError, fn -> Event.parse_data(:this_isnt_an_event, nil) end
    end

    test "parses :ready" do
      data = %{
        "v" => 8,
        "user" => user(),
        "private_channels" => [],
        "guilds" => [guild()],
        "session_id" => random_hex(8),
        "shard" => [0, 1],
        "application" => application()
      }

      parsed = Event.parse_data(:ready, data)

      parsed
      |> assert_field(:v, data["v"])
      |> assert_field(:user, Models.User.parse(data["user"]))
      |> assert_field(:private_channels, data["private_channels"])
      |> assert_field(:guilds, Model.parse_list(data["guilds"], &Models.Guild.parse/1))
      |> assert_field(:session_id, data["session_id"])
      |> assert_field(:shard, ShardInfo.from_list(data["shard"]))
      |> assert_field(:application, Models.Application.parse(data["application"]))
    end

    test "parses :channel_create" do
      data = channel()
      parsed = Event.parse_data(:channel_create, data)
      assert parsed == Models.Channel.parse(data)
    end

    test "parses :channel_update" do
      data = channel()
      parsed = Event.parse_data(:channel_update, data)
      assert parsed == Models.Channel.parse(data)
    end

    test "parses :channel_delete" do
      data = channel()
      parsed = Event.parse_data(:channel_delete, data)
      assert parsed == Models.Channel.parse(data)
    end

    test "parses :channel_pins_update" do
      data = %{
        "guild_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "last_pin_timestamp" => DateTime.to_iso8601(DateTime.utc_now())
      }

      parsed = Event.parse_data(:channel_pins_update, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:last_pin_timestamp, Models.Timestamp.parse(data["last_pin_timestamp"]))
    end

    test "parses :guild_create" do
      data = guild()
      parsed = Event.parse_data(:guild_create, data)
      assert parsed == Models.Guild.parse(data)
    end

    test "parses :guild_update" do
      data = guild()
      parsed = Event.parse_data(:guild_update, data)
      assert parsed == Models.Guild.parse(data)
    end

    test "parses :guild_delete" do
      data = guild()
      parsed = Event.parse_data(:guild_delete, data)
      assert parsed == Models.Guild.parse(data)
    end

    test "parses :guild_ban_add" do
      data = %{
        "guild_id" => random_snowflake(),
        "user" => user()
      }

      parsed = Event.parse_data(:guild_ban_add, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:user, Models.User.parse(data["user"]))
    end

    test "parses :guild_ban_remove" do
      data = %{
        "guild_id" => random_snowflake(),
        "user" => user()
      }

      parsed = Event.parse_data(:guild_ban_remove, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:user, Models.User.parse(data["user"]))
    end

    test "parses :guild_emojis_update" do
      data = %{
        "guild_id" => random_snowflake(),
        "emojis" => [emoji(), emoji()]
      }

      parsed = Event.parse_data(:guild_emojis_update, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:emojis, Model.parse_list(data["emojis"], &Models.Emoji.parse/1))
    end

    test "parses :guild_integrations_update" do
      data = %{"guild_id" => random_snowflake()}

      parsed = Event.parse_data(:guild_integrations_update, data)

      assert_field(parsed, :guild_id, Models.Snowflake.parse(data["guild_id"]))
    end

    test "parses :guild_member_add" do
      data = Map.put(member(), "guild_id", random_snowflake())

      parsed = Event.parse_data(:guild_member_add, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:member, Models.Member.parse(data))
    end

    test "parses :guild_member_remove" do
      data = %{
        "guild_id" => random_snowflake(),
        "user" => user()
      }

      parsed = Event.parse_data(:guild_member_remove, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:user, Models.User.parse(data["user"]))
    end

    test "parses :guild_member_update" do
      data = %{
        "guild_id" => random_snowflake(),
        "roles" => [random_snowflake(), random_snowflake()],
        "user" => user(),
        "nick" => random_hex(8),
        "joined_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "premium_since" => DateTime.to_iso8601(DateTime.utc_now()),
        "pending" => false
      }

      parsed = Event.parse_data(:guild_member_update, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(
        :roles,
        Model.parse_list(data["roles"], &Models.Snowflake.parse/1)
      )
      |> assert_field(:user, Models.User.parse(data["user"]))
      |> assert_field(:nick, data["nick"])
      |> assert_field(:joined_at, Models.Timestamp.parse(data["joined_at"]))
      |> assert_field(:premium_since, Models.Timestamp.parse(data["premium_since"]))
      |> assert_field(:pending, data["pending"])
    end

    test "parses :guild_role_create" do
      data = %{
        "guild_id" => random_snowflake(),
        "role" => role()
      }

      parsed = Event.parse_data(:guild_role_create, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:role, Models.Role.parse(data["role"]))
    end

    test "parses :guild_role_update" do
      data = %{
        "guild_id" => random_snowflake(),
        "role" => role()
      }

      parsed = Event.parse_data(:guild_role_update, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:role, Models.Role.parse(data["role"]))
    end

    test "parses :guild_role_delete" do
      data = %{
        "guild_id" => random_snowflake(),
        "role_id" => random_snowflake()
      }

      parsed = Event.parse_data(:guild_role_delete, data)

      parsed
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:role_id, Models.Snowflake.parse(data["role_id"]))
    end

    test "parses :invite_create" do
      data = %{
        "channel_id" => random_snowflake(),
        "code" => random_hex(8),
        "created_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "guild_id" => random_snowflake(),
        "inviter" => user(),
        "max_age" => :rand.uniform(3600),
        "max_uses" => :rand.uniform(25),
        "target_user" => user(),
        "target_user_type" => 1,
        "temporary" => false,
        "uses" => :rand.uniform(10)
      }

      parsed = Event.parse_data(:invite_create, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:code, data["code"])
      |> assert_field(:created_at, Models.Timestamp.parse(data["created_at"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:inviter, Models.User.parse(data["inviter"]))
      |> assert_field(:max_age, data["max_age"])
      |> assert_field(:max_uses, data["max_uses"])
      |> assert_field(:target_user, Models.User.parse(data["target_user"]))
      |> assert_field(:target_user_type, :stream)
      |> assert_field(:temporary, data["temporary"])
      |> assert_field(:uses, data["uses"])
    end

    test "parses :invite_delete" do
      data = %{
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "code" => random_hex(8)
      }

      parsed = Event.parse_data(:invite_delete, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:code, data["code"])
    end

    test "parses :message_create" do
      data = message()
      parsed = Event.parse_data(:message_create, data)
      assert parsed == Models.Message.parse(data)
    end

    test "parses :message_update" do
      data = message()
      parsed = Event.parse_data(:message_update, data)
      assert parsed == Models.Message.parse(data)
    end

    test "parses :message_delete" do
      data = %{
        "id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      }

      parsed = Event.parse_data(:message_delete, data)

      parsed
      |> assert_field(:id, Models.Snowflake.parse(data["id"]))
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
    end

    test "parses :message_delete_bulk" do
      data = %{
        "ids" => [random_snowflake(), random_snowflake()],
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      }

      parsed = Event.parse_data(:message_delete_bulk, data)

      parsed
      |> assert_field(:ids, Model.parse_list(data["ids"], &Models.Snowflake.parse/1))
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
    end

    test "parses :message_reaction_add" do
      data = %{
        "user_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "message_id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "member" => member(),
        "emoji" => emoji()
      }

      parsed = Event.parse_data(:message_reaction_add, data)

      parsed
      |> assert_field(:user_id, Models.Snowflake.parse(data["user_id"]))
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:message_id, Models.Snowflake.parse(data["message_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:member, Models.Member.parse(data["member"]))
      |> assert_field(:emoji, Models.Emoji.parse(data["emoji"]))
    end

    test "parses :message_reaction_remove" do
      data = %{
        "user_id" => random_snowflake(),
        "channel_id" => random_snowflake(),
        "message_id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "emoji" => emoji()
      }

      parsed = Event.parse_data(:message_reaction_remove, data)

      parsed
      |> assert_field(:user_id, Models.Snowflake.parse(data["user_id"]))
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:message_id, Models.Snowflake.parse(data["message_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:emoji, Models.Emoji.parse(data["emoji"]))
    end

    test "parses :message_reaction_remove_all" do
      data = %{
        "channel_id" => random_snowflake(),
        "message_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      }

      parsed = Event.parse_data(:message_reaction_remove_all, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:message_id, Models.Snowflake.parse(data["message_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
    end

    test "parses :message_reaction_remove_emoji" do
      data = %{
        "channel_id" => random_snowflake(),
        "message_id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "emoji" => emoji()
      }

      parsed = Event.parse_data(:message_reaction_remove_emoji, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:message_id, Models.Snowflake.parse(data["message_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:emoji, Models.Emoji.parse(data["emoji"]))
    end

    test "parses :presence_update" do
      data = presence()
      parsed = Event.parse_data(:presence_update, data)
      assert parsed == Models.Presence.parse(data)
    end

    test "parses :typing_start" do
      data = %{
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake(),
        "user_id" => random_snowflake(),
        "timestamp" => DateTime.to_unix(DateTime.utc_now(), :millisecond),
        "member" => member()
      }

      parsed = Event.parse_data(:typing_start, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:user_id, Models.Snowflake.parse(data["user_id"]))
      |> assert_field(:timestamp, Models.Timestamp.parse_unix(data["timestamp"]))
      |> assert_field(:member, Models.Member.parse(data["member"]))
    end

    test "parses :user_update" do
      data = user()
      parsed = Event.parse_data(:user_update, data)
      assert parsed == Models.User.parse(data)
    end

    test "parses :voice_state_update" do
      data = voice_state()
      parsed = Event.parse_data(:voice_state_update, data)
      assert parsed == Models.VoiceState.parse(data)
    end

    test "parses :voice_server_update" do
      data = %{
        "token" => random_hex(16),
        "guild_id" => random_snowflake(),
        "endpoint" => random_hex(32)
      }

      parsed = Event.parse_data(:voice_server_update, data)

      parsed
      |> assert_field(:token, data["token"])
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
      |> assert_field(:endpoint, data["endpoint"])
    end

    test "parses :webhooks_update" do
      data = %{
        "channel_id" => random_snowflake(),
        "guild_id" => random_snowflake()
      }

      parsed = Event.parse_data(:webhooks_update, data)

      parsed
      |> assert_field(:channel_id, Models.Snowflake.parse(data["channel_id"]))
      |> assert_field(:guild_id, Models.Snowflake.parse(data["guild_id"]))
    end

    test "doesn't parse :application_command_create" do
      data = random_snowflake()
      parsed = Event.parse_data(:application_command_create, data)
      assert parsed == data
    end

    test "doesn't parse :application_command_update" do
      data = random_snowflake()
      parsed = Event.parse_data(:application_command_update, data)
      assert parsed == data
    end

    test "doesn't parse :application_command_delete" do
      data = random_snowflake()
      parsed = Event.parse_data(:application_command_delete, data)
      assert parsed == data
    end

    test "doesn't parse :interaction_create" do
      data = random_snowflake()
      parsed = Event.parse_data(:interaction_create, data)
      assert parsed == data
    end
  end
end
