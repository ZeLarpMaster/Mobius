defmodule Mobius.Actions.ChannelTest do
  use ExUnit.Case

  import Mobius.Fixtures
  import Mobius.Generators
  import Tesla.Mock, only: [mock: 1]

  alias Mobius.Actions.Channel
  alias Mobius.Models
  alias Mobius.Rest.Client

  setup :reset_services
  setup :create_rest_client
  setup :stub_socket
  setup :stub_ratelimiter
  setup :get_shard
  setup :handshake_shard

  describe "get_channel/1" do
    setup do
      channel_id = random_snowflake()
      raw = channel(id: channel_id)
      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :get, url: ^url} -> json(raw) end)
      [channel_id: channel_id, raw_channel: raw]
    end

    test "returns the channel if successful", ctx do
      {:ok, channel} = Channel.get_channel(ctx.channel_id)
      assert channel == Models.Channel.parse(ctx.raw_channel)
    end
  end

  describe "edit_channel/2" do
    setup do
      channel_id = random_snowflake()
      updated_raw = channel(id: channel_id, name: "new_name")
      url = Client.base_url() <> "/channels/#{channel_id}"
      mock(fn %{method: :patch, url: ^url} -> json(updated_raw) end)
      [channel_id: channel_id, raw_updated_channel: updated_raw]
    end

    test "returns the updated channel if successful", ctx do
      {:ok, channel} = Channel.edit_channel(ctx.channel_id, %{name: "new_name"})
      assert channel == Models.Channel.parse(ctx.raw_updated_channel)
    end

    test "returns an error if the channel name length is outside the range", ctx do
      error_message = "Expected name to contain between 2 and 100 characters"

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{name: ""})
      assert_has_error(errors, error_message)

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{name: random_text(101)})
      assert_has_error(errors, error_message)
    end

    test "returns an error if the channel type is in the allowed list", ctx do
      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{type: :some_invalid_type})
      assert_has_error(errors, "can only be converted to text or news")
    end

    test "returns an error if the channel topic length is outside the allowed range", ctx do
      error_message = "Expected topic to contain between 0 and 1024 characters"

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{topic: random_text(1025)})
      assert_has_error(errors, error_message)
    end

    test "returns an error if the channel rate limit is outside the allowed range", ctx do
      error_message = "Expected rate_limit_per_user to be between 0 and 21600"

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{rate_limit_per_user: -1})
      assert_has_error(errors, error_message)

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{rate_limit_per_user: 21_601})
      assert_has_error(errors, error_message)
    end

    test "returns an error if the channel bitrate is outside the allowed range", ctx do
      error_message = "Expected bitrate to be between 8000 and 96000"

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{bitrate: 7999})
      assert_has_error(errors, error_message)

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{bitrate: 96_001})
      assert_has_error(errors, error_message)
    end

    test "returns an error if the channel user limit is outside the allowed range", ctx do
      error_message = "Expected user_limit to be between 0 and 99"

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{user_limit: -1})
      assert_has_error(errors, error_message)

      {:error, errors} = Channel.edit_channel(ctx.channel_id, %{user_limit: 100})
      assert_has_error(errors, error_message)
    end
  end

  defp assert_has_error(errors, expected_error)
       when is_list(errors) and is_binary(expected_error) do
    assert Enum.any?(errors, fn error -> error =~ expected_error end),
           "Error message not found. Expected #{inspect(expected_error)}, received #{inspect(errors)}."
  end
end
