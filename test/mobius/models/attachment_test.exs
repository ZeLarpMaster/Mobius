defmodule Mobius.Models.AttachmentTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Models.Attachment
  alias Mobius.Models.Snowflake

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Attachment.parse("string")
      assert nil == Attachment.parse(42)
      assert nil == Attachment.parse(true)
      assert nil == Attachment.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Attachment.parse()
      |> assert_field(:id, nil)
      |> assert_field(:filename, nil)
      |> assert_field(:size, nil)
      |> assert_field(:url, nil)
      |> assert_field(:proxy_url, nil)
      |> assert_field(:height, nil)
      |> assert_field(:width, nil)
    end

    test "parses all fields as expected" do
      map = attachment()

      map
      |> Attachment.parse()
      |> assert_field(:id, Snowflake.parse(map["id"]))
      |> assert_field(:filename, map["filename"])
      |> assert_field(:size, map["size"])
      |> assert_field(:url, map["url"])
      |> assert_field(:proxy_url, map["proxy_url"])
      |> assert_field(:height, map["height"])
      |> assert_field(:width, map["width"])
    end
  end
end
