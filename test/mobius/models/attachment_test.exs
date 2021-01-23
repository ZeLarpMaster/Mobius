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
      |> check_field(:id, nil)
      |> check_field(:filename, nil)
      |> check_field(:size, nil)
      |> check_field(:url, nil)
      |> check_field(:proxy_url, nil)
      |> check_field(:height, nil)
      |> check_field(:width, nil)
    end

    test "parses all fields as expected" do
      map = attachment()

      map
      |> Attachment.parse()
      |> check_field(:id, Snowflake.parse(map["id"]))
      |> check_field(:filename, map["filename"])
      |> check_field(:size, map["size"])
      |> check_field(:url, map["url"])
      |> check_field(:proxy_url, map["proxy_url"])
      |> check_field(:height, map["height"])
      |> check_field(:width, map["width"])
    end
  end
end
