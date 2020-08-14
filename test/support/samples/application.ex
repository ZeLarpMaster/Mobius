defmodule Mobius.Samples.Application do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_application(:minimal | :full) :: map
  def raw_application(:minimal) do
    %{
      "id" => "#{random_snowflake()}",
      "name" => random_hex(8),
      "icon" => random_hex(16),
      "description" => random_hex(16),
      "bot_public" => false,
      "bot_require_code_grant" => false,
      "owner" => Samples.User.raw_user(:minimal),
      "summary" => random_hex(16),
      "verify_key" => random_hex(16),
      "team" => nil
    }
  end

  def raw_application(:full) do
    Map.merge(raw_application(:minimal), %{
      "team" => %{
        "icon" => random_hex(16),
        "id" => "#{random_snowflake()}",
        "owner_user_id" => "#{random_snowflake()}",
        "members" => [
          %{
            "membership_state" => 2,
            "permissions" => ["*"],
            "team_id" => "#{random_snowflake()}",
            "user" => Samples.User.raw_user(:minimal)
          }
        ]
      }
    })
  end
end
