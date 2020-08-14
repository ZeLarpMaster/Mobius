defmodule Mobius.Samples.User do
  @moduledoc false

  import Mobius.Fixtures

  @spec raw_user(:full | :minimal) :: map
  def raw_user(:minimal) do
    %{
      "id" => "#{random_snowflake()}",
      "username" => random_hex(8),
      "discriminator" => random_discriminator(),
      "avatar" => random_hex(16)
    }
  end

  def raw_user(:full) do
    %{
      "bot" => false,
      "system" => false,
      "mfa_enabled" => true,
      "locale" => "en-US",
      "verified" => true,
      "email" => "#{random_hex(8)}@email.com",
      "flags" => Bitwise.<<<(1, 17),
      "premium_type" => 2,
      "public_flags" => Bitwise.<<<(1, 17)
    }
    |> Map.merge(raw_user(:minimal))
  end

  defp random_discriminator do
    :rand.uniform(9999)
    |> Integer.to_string()
    |> String.pad_leading(4, "0")
  end
end
