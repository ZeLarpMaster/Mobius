defmodule Mobius.Models.MessageTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils
  import Mobius.Model

  alias Mobius.Models.Attachment
  alias Mobius.Models.ChannelMention
  alias Mobius.Models.Embed
  alias Mobius.Models.Member
  alias Mobius.Models.Message
  alias Mobius.Models.MessageActivity
  alias Mobius.Models.MessageApplication
  alias Mobius.Models.MessageReference
  alias Mobius.Models.Reaction
  alias Mobius.Models.Snowflake
  alias Mobius.Models.Sticker
  alias Mobius.Models.Timestamp
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Message.parse("string")
      assert nil == Message.parse(42)
      assert nil == Message.parse(true)
      assert nil == Message.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Message.parse()
      |> assert_field(:id, nil)
      |> assert_field(:channel_id, nil)
      |> assert_field(:guild_id, nil)
      |> assert_field(:author, nil)
      |> assert_field(:member, nil)
      |> assert_field(:content, nil)
      |> assert_field(:timestamp, nil)
      |> assert_field(:edited_timestamp, nil)
      |> assert_field(:tts, nil)
      |> assert_field(:mention_everyone, nil)
      |> assert_field(:mentions, nil)
      |> assert_field(:mention_roles, nil)
      |> assert_field(:mention_channels, nil)
      |> assert_field(:attachments, nil)
      |> assert_field(:embeds, nil)
      |> assert_field(:reactions, nil)
      |> assert_field(:nonce, nil)
      |> assert_field(:pinned, nil)
      |> assert_field(:webhook_id, nil)
      |> assert_field(:type, nil)
      |> assert_field(:activity, nil)
      |> assert_field(:application, nil)
      |> assert_field(:message_reference, nil)
      |> assert_field(:flags, nil)
      |> assert_field(:stickers, nil)
      |> assert_field(:referenced_message, nil)
    end

    test "parses all fields as expected" do
      map = message(type: 19, referenced_message: message())

      mentions = parse_list(map["mentions"], &Member.parse(Map.put(&1["member"], "user", &1)))
      channels = parse_list(map["mention_channels"], &ChannelMention.parse/1)

      map
      |> Message.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:channel_id, Snowflake.parse(map["channel_id"]))
      |> assert_field(:guild_id, Snowflake.parse(map["guild_id"]))
      |> assert_field(:author, User.parse(map["author"]))
      |> assert_field(:member, Member.parse(Map.put(map["member"], "user", map["author"])))
      |> assert_field(:content, map["content"])
      |> assert_field(:timestamp, Timestamp.parse(map["timestamp"]))
      |> assert_field(:edited_timestamp, Timestamp.parse(map["edited_timestamp"]))
      |> assert_field(:tts, map["tts"])
      |> assert_field(:mention_everyone, map["mention_everyone"])
      |> assert_field(:mentions, mentions)
      |> assert_field(:mention_roles, parse_list(map["mention_roles"], &Snowflake.parse/1))
      |> assert_field(:mention_channels, channels)
      |> assert_field(:attachments, parse_list(map["attachments"], &Attachment.parse/1))
      |> assert_field(:embeds, parse_list(map["embeds"], &Embed.parse/1))
      |> assert_field(:reactions, parse_list(map["reactions"], &Reaction.parse/1))
      |> assert_field(:nonce, map["nonce"])
      |> assert_field(:pinned, map["pinned"])
      |> assert_field(:webhook_id, Snowflake.parse(map["webhook_id"]))
      |> assert_field(:type, :reply)
      |> assert_field(:activity, MessageActivity.parse(map["activity"]))
      |> assert_field(:application, MessageApplication.parse(map["application"]))
      |> assert_field(:message_reference, MessageReference.parse(map["message_reference"]))
      |> assert_field(:flags, MapSet.new([:suppress_embeds]))
      |> assert_field(:stickers, parse_list(map["stickers"], &Sticker.parse/1))
      |> assert_field(:referenced_message, Message.parse(map["referenced_message"]))
    end
  end
end
