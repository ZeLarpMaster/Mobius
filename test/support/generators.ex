defmodule Mobius.Generators do
  @moduledoc "Functions to generate models as given by Discord (as maps with strings as keys)"

  import Mobius.Fixtures

  @spec user(keyword) :: map
  def user(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "username" => random_hex(8),
      "discriminator" => random_discriminator(),
      "avatar" => random_hex(8),
      "bot" => true,
      "system" => false,
      "mfa_enabled" => false,
      "locale" => "en_US",
      "verified" => false,
      "email" => nil,
      "flags" => Bitwise.<<<(1, 16),
      "premium_type" => 0,
      "public_flags" => Bitwise.<<<(1, 16)
    }

    merge_opts(defaults, opts)
  end

  @spec partial_user(keyword) :: map
  def partial_user(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "username" => random_hex(8),
      "discriminator" => random_discriminator(),
      "avatar" => random_hex(8)
    }

    merge_opts(defaults, opts)
  end

  @spec team_member(keyword) :: map
  def team_member(opts \\ []) do
    defaults = %{
      "membership_state" => 2,
      "permissions" => ["*"],
      "team_id" => random_snowflake(),
      "user" => partial_user(Keyword.get(opts, :user, []))
    }

    merge_opts(defaults, opts)
  end

  defp merge_opts(defaults, opts) do
    opts_map =
      opts
      |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
      |> Map.new()

    Map.merge(defaults, opts_map)
  end
end
