defmodule Mobius.CogTestUtils do
  @moduledoc "A module of utilities to help with testing cogs"

  import Tesla.Mock
  import ExUnit.Assertions
  import ExUnit.Callbacks

  alias Mobius.Actions.Message

  @spec setup_rest_api_mock(any) :: no_return
  def setup_rest_api_mock(_ctx) do
    test_pid = self()

    # Put back the default global mock because mock_global isn't a stack, it's one global value
    # If this causes issues elsewhere, we'll need to implement our own Tesla.Mock adapter
    # which uses a stack of mocks instead
    on_exit(&Mobius.Fixtures.mock_gateway_bot/0)

    mock_global(fn env ->
      send(test_pid, env)
      {200, [], %{}}
    end)
  end

  @spec assert_message_sent(Message.message_body()) :: :ok
  def assert_message_sent(message) do
    json_message = Jason.encode!(message)
    %Tesla.Env{url: url} = assert_receive %Tesla.Env{body: ^json_message}
    # This only works if the channel_id used to send the message was `nil`
    assert String.ends_with?(url, "/channels/:channel_id/messages")
    :ok
  end
end
