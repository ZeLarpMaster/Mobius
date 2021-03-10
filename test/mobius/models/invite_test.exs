defmodule Mobius.Models.InviteTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Channel
  alias Mobius.Models.Invite
  alias Mobius.Models.InviteMetadata
  alias Mobius.Models.User

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Invite.parse("string")
      assert nil == Invite.parse(42)
      assert nil == Invite.parse(true)
      assert nil == Invite.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Invite.parse()
      |> assert_field(:code, nil)
      |> assert_field(:guild, nil)
      |> assert_field(:channel, nil)
      |> assert_field(:inviter, nil)
      |> assert_field(:target_user, nil)
      |> assert_field(:target_user_type, nil)
      |> assert_field(:metadata, nil)
      |> assert_field(:approximate_presence_count, nil)
      |> assert_field(:approximate_member_count, nil)
    end

    test "parses metadata as nil if no metadata field is present" do
      invite()
      |> Map.drop(["uses", "max_uses", "max_age", "temporary", "created_at"])
      |> Invite.parse()
      |> assert_field(:metadata, nil)
    end

    test "parses all fields as expected" do
      map = invite()

      map
      |> Invite.parse()
      |> assert_field(:code, map["code"])
      |> assert_field(:guild, map["guild"])
      |> assert_field(:channel, Channel.parse(map["channel"]))
      |> assert_field(:inviter, User.parse(map["inviter"]))
      |> assert_field(:target_user, User.parse(map["target_user"]))
      |> assert_field(:target_user_type, :stream)
      |> assert_field(:metadata, InviteMetadata.parse(map))
      |> assert_field(:approximate_presence_count, map["approximate_presence_count"])
      |> assert_field(:approximate_member_count, map["approximate_member_count"])
    end
  end
end
