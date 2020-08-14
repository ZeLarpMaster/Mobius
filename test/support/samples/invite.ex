defmodule Mobius.Samples.Invite do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_invite(:minimal | :full) :: map
  def raw_invite(:minimal) do
    %{
      "code" => random_hex(8),
      "channel" => Samples.Channel.raw_channel(:minimal)
    }
  end

  def raw_invite(:full) do
    %{
      "code" => random_hex(8),
      "channel" => Samples.Channel.raw_channel(:minimal),
      "guild" => raw_invite_guild(:full),
      "inviter" => Samples.User.raw_user(:minimal),
      "target_user" => Samples.User.raw_user(:minimal),
      "target_user_type" => 1,
      "approximate_presence_count" => :rand.uniform(8000),
      "approximate_member_count" => :rand.uniform(5000),
      "uses" => :rand.uniform(50),
      "max_uses" => :rand.uniform(100),
      "max_age" => :rand.uniform(100_000),
      "temporary" => true,
      "created_at" => Samples.Other.iso8601()
    }
  end

  @spec raw_invite_guild(:full) :: map
  def raw_invite_guild(:full) do
    %{
      "id" => "#{random_snowflake()}",
      "banner" => random_hex(8),
      "description" => random_hex(16),
      "icon" => random_hex(8),
      "name" => random_hex(8),
      "splash" => random_hex(8),
      "vanity_url_code" => random_hex(8),
      "verification_level" => 3,
      "features" => ["PUBLIC"]
    }
  end
end
