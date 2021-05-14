defmodule Mobius.CogTestUtils do
  @moduledoc "A module of utilities to help with testing cogs"

  import Tesla.Mock
  import ExUnit.Assertions
  import ExUnit.Callbacks

  alias Mobius.Actions.Message
  alias Mobius.Rest.Client

  @doc "Starts a cog in the test supervision tree using `start_supervised!/2`"
  @spec start_cog(module()) :: :ok
  def start_cog(cog) do
    start_supervised!(cog, restart: :temporary)
    Process.monitor(cog)
    :ok
  end

  @doc "Asserts that the cog died and returns the exit reason"
  @spec assert_cog_died(module()) :: any
  def assert_cog_died(cog) do
    assert_receive {:DOWN, _ref, :process, {^cog, _host}, reason}
    reason
  end

  @doc "Sets up the mock for rest API calls to enable action assertions"
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

  @doc "Asserts that a message was sent returns the body of the request"
  @spec assert_message_sent(Message.message_body()) :: any
  defmacro assert_message_sent(expectation) do
    quote do
      # This only works if the channel_id used to send the message was `nil`
      url = Client.base_url() <> "/channels/:channel_id/messages"

      %Tesla.Env{opts: opts} = assert_receive %Tesla.Env{method: :post, url: ^url}
      body = Keyword.fetch!(opts, :req_body)
      assert unquote(expectation) = body
    end
  end
end
