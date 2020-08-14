defmodule Mobius.Samples.Emoji do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_emoji(:full | :minimal) :: map
  def raw_emoji(:minimal) do
    %{
      "id" => "#{random_snowflake()}",
      "name" => random_hex(8)
    }
  end

  def raw_emoji(:full) do
    %{
      "animated" => false,
      "available" => true,
      "managed" => false,
      "require_colons" => true,
      "roles" => ["#{random_snowflake()}"],
      "user" => Samples.User.raw_user(:minimal)
    }
    |> Map.merge(raw_emoji(:minimal))
  end
end
