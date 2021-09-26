defmodule Mobius.Models.EmbedTest do
  use ExUnit.Case, async: true

  import Mobius.Generators
  import Mobius.TestUtils

  alias Mobius.Model
  alias Mobius.Models.Embed
  alias Mobius.Models.Embed.Author
  alias Mobius.Models.Embed.Field
  alias Mobius.Models.Embed.Footer
  alias Mobius.Models.Embed.Media
  alias Mobius.Models.Embed.Provider
  alias Mobius.Models.Timestamp

  describe "parse/1" do
    test "returns nil for non-maps" do
      assert nil == Embed.parse("string")
      assert nil == Embed.parse(42)
      assert nil == Embed.parse(true)
      assert nil == Embed.parse(nil)
    end

    test "defaults to nil for all fields" do
      %{}
      |> Embed.parse()
      |> assert_field(:title, nil)
      |> assert_field(:type, nil)
      |> assert_field(:description, nil)
      |> assert_field(:url, nil)
      |> assert_field(:timestamp, nil)
      |> assert_field(:color, nil)
      |> assert_field(:footer, nil)
      |> assert_field(:image, nil)
      |> assert_field(:thumbnail, nil)
      |> assert_field(:video, nil)
      |> assert_field(:provider, nil)
      |> assert_field(:author, nil)
      |> assert_field(:fields, nil)
    end

    test "parses all fields as expected" do
      map = embed()

      map
      |> Embed.parse()
      |> assert_field(:title, map["title"])
      |> assert_field(:type, :rich)
      |> assert_field(:description, map["description"])
      |> assert_field(:url, map["url"])
      |> assert_field(:timestamp, Timestamp.parse(map["timestamp"]))
      |> assert_field(:color, map["color"])
      |> assert_field(:footer, Footer.parse(map["footer"]))
      |> assert_field(:image, Media.parse(map["image"]))
      |> assert_field(:thumbnail, Media.parse(map["thumbnail"]))
      |> assert_field(:video, Media.parse(map["video"]))
      |> assert_field(:provider, Provider.parse(map["provider"]))
      |> assert_field(:author, Author.parse(map["author"]))
      |> assert_field(:fields, Model.parse_list(map["fields"], &Field.parse/1))
    end
  end
end
