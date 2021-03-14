defmodule Mobius.Actions.ReactionTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Reaction
  alias Mobius.Models.Emoji
  alias Mobius.Models.User
  alias Mobius.Rest.Client

  setup :reset_services
  setup :create_rest_client
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard
  setup :handshake_shard

  describe "create_reaction/3 with a custom emoji" do
    setup do
      [managed: true]
      |> create_emoji()
      |> mock_call()
    end

    test "returns :ok if successful", ctx do
      :ok = Reaction.create_reaction(ctx.emoji, ctx.channel_id, ctx.message_id)
    end

    test "returns an error if no id is provided", ctx do
      emoji = %Emoji{ctx.emoji | id: nil}
      {:error, error} = Reaction.create_reaction(emoji, ctx.channel_id, ctx.message_id)
      assert error =~ "Custom emojis require an ID"
    end

    test "returns an error if no name is provided", ctx do
      emoji = %Emoji{ctx.emoji | name: nil}
      {:error, error} = Reaction.create_reaction(emoji, ctx.channel_id, ctx.message_id)
      assert error =~ "Custom emojis require a name"
    end
  end

  describe "create_reaction/3 with a built-in emoji" do
    setup do
      [managed: false]
      |> create_emoji()
      |> mock_call()
    end

    test "returns :ok if successful", ctx do
      :ok = Reaction.create_reaction(ctx.emoji, ctx.channel_id, ctx.message_id)
    end

    test "returns an error if no name is provided", ctx do
      emoji = %Emoji{ctx.emoji | name: nil}
      {:error, error} = Reaction.create_reaction(emoji, ctx.channel_id, ctx.message_id)
      assert error =~ "Built-in emojis require a name"
    end
  end

  defp mock_call(emoji) do
    message_id = random_snowflake()
    channel_id = random_snowflake()

    emoji_string =
      case emoji do
        %Emoji{managed: true} -> "#{emoji.name}:#{emoji.id}"
        %Emoji{managed: false} -> emoji.name
      end

    url =
      Client.base_url() <>
        "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji_string}/@me"

    mock(fn %{method: :put, url: ^url} -> empty_response() end)

    [message_id: message_id, channel_id: channel_id, emoji: emoji]
  end

  defp create_emoji(opts) do
    %Emoji{
      id: random_snowflake(),
      name: "party_parrot",
      roles: nil,
      user: %User{
        id: random_snowflake(),
        username: "Bob",
        discriminator: "123456",
        avatar: nil
      },
      require_colons: true,
      managed: Keyword.get(opts, :managed),
      animated: false,
      available: true
    }
  end
end
