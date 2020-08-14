defmodule Mobius.Samples.Presence do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_presence(:full) :: map
  def raw_presence(:full) do
    %{
      "user" => Samples.User.raw_user(:minimal),
      "roles" => ["#{random_snowflake()}"],
      "game" => nil,
      "guild_id" => "#{random_snowflake()}",
      "status" => "online",
      "activities" => [],
      "client_status" => %{"desktop" => "online"},
      "nick" => random_hex(8)
    }
  end
end
