defmodule Mobius.Services.CogLoaderTest do
  use ExUnit.Case

  alias Mobius.Services.CogLoader

  import Mobius.Fixtures

  setup :get_shard
  setup :reset_services
  setup :stub_socket
  setup :handshake_shard

  test "should start initial cogs automatically" do
    assert {:error, {:already_started, _pid}} = CogLoader.load_cog(Mobius.Cogs.PingPong)
  end

  describe "load_cog/1" do
    test "should start the cog process" do
      assert :ok == CogLoader.load_cog(Mobius.Stubs.Cog)
      assert {:error, {:already_started, _pid}} = CogLoader.load_cog(Mobius.Stubs.Cog)
    end
  end
end
