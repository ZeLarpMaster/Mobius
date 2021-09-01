defmodule Mobius.CogCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up a cog.

  Such tests will have access to all functions in `Mobius.CogTestUtils`

  It will also setup the necessary mocks and prepare the bot's state to receive events
  """

  use ExUnit.CaseTemplate

  import Mobius.Fixtures
  import Mobius.CogTestUtils

  using _opts do
    quote do
      import Mobius.Fixtures, only: [send_command_payload: 1]
      import Mobius.CogTestUtils
    end
  end

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard
  setup :setup_rest_api_mock
end
