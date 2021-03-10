defmodule Mobius.Models.InviteMetadataTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.InviteMetadata
  alias Mobius.Models.Timestamp

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == InviteMetadata.parse("string")
      assert nil == InviteMetadata.parse(42)
      assert nil == InviteMetadata.parse(true)
      assert nil == InviteMetadata.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> InviteMetadata.parse()
      |> assert_field(:uses, nil)
      |> assert_field(:max_uses, nil)
      |> assert_field(:max_age, nil)
      |> assert_field(:temporary, nil)
      |> assert_field(:created_at, nil)
    end

    test "parses all fields as expected" do
      # All metadata fields are in invites
      map = invite()

      map
      |> InviteMetadata.parse()
      |> assert_field(:uses, map["uses"])
      |> assert_field(:max_uses, map["max_uses"])
      |> assert_field(:max_age, map["max_age"])
      |> assert_field(:temporary, map["temporary"])
      |> assert_field(:created_at, Timestamp.parse(map["created_at"]))
    end
  end
end
