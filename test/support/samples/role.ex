defmodule Mobius.Samples.Role do
  @moduledoc false

  import Mobius.Fixtures

  @spec raw_role(:everyone | :full) :: map
  def raw_role(:everyone) do
    %{
      "color" => 0,
      "hoist" => false,
      "id" => "#{random_snowflake()}",
      "managed" => false,
      "mentionable" => false,
      "name" => "@everyone",
      "permissions" => :rand.uniform(2_000_000),
      "position" => 0
    }
  end

  def raw_role(:full) do
    %{
      "color" => :rand.uniform(Bitwise.<<<(1, 24)),
      "hoist" => true,
      "id" => "#{random_snowflake()}",
      "managed" => false,
      "mentionable" => false,
      "name" => random_hex(8),
      "permissions" => :rand.uniform(2_000_000),
      "position" => 1
    }
  end
end
