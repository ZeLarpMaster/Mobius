defmodule Mobius.Samples.Channel do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_channel(:full | :minimal) :: map
  def raw_channel(:minimal) do
    %{
      "id" => "#{random_snowflake()}",
      "type" => 0
    }
  end

  def raw_channel(:full) do
    %{
      "guild_id" => "#{random_snowflake()}",
      "position" => 4,
      "permission_overwrites" => [
        %{"allow" => 42, "deny" => 0, "id" => "456", "type" => "member"}
      ],
      "name" => random_hex(16),
      "topic" => random_hex(16),
      "nsfw" => false,
      "last_message_id" => "#{random_snowflake()}",
      "bitrate" => 44000,
      "user_limit" => 10,
      "rate_limit_per_user" => 60,
      "recipients" => [Samples.User.raw_user(:minimal)],
      "icon" => random_hex(8),
      "owner_id" => "#{random_snowflake()}",
      "application_id" => "#{random_snowflake()}",
      "parent_id" => "#{random_snowflake()}",
      "last_pin_timestamp" => Samples.Other.iso8601()
    }
    |> Map.merge(raw_channel(:minimal))
  end
end
