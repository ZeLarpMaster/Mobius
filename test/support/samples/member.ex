defmodule Mobius.Samples.Member do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_member(:full | :minimal) :: map
  def raw_member(:minimal) do
    %{
      "nick" => random_hex(8),
      "roles" => ["#{random_snowflake()}"],
      "joined_at" => Samples.Other.iso8601(),
      "deaf" => false,
      "mute" => false
    }
  end

  def raw_member(:full) do
    %{
      "user" => Samples.User.raw_user(:minimal),
      "premium_since" => Samples.Other.iso8601()
    }
    |> Map.merge(raw_member(:minimal))
  end
end
