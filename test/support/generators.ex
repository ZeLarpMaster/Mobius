defmodule Mobius.Generators do
  @moduledoc "Functions to generate models as given by Discord (as maps with strings as keys)"

  import Mobius.Fixtures

  @spec member(keyword) :: map
  def member(opts \\ []) do
    defaults = %{
      "user" => user(Keyword.get(opts, :user, [])),
      "nick" => random_hex(8),
      "roles" => [random_snowflake(), random_snowflake(), random_snowflake()],
      "joined_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "premium_since" => DateTime.to_iso8601(DateTime.utc_now()),
      "deaf" => true,
      "mute" => true,
      "pending" => false
    }

    merge_opts(defaults, opts)
  end

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

  @spec role(keyword) :: map
  def role(opts \\ []) do
    defaults = %{
      "id" => random_snowflake(),
      "name" => random_hex(8),
      "color" => :rand.uniform(256 * 256 * 256),
      "hoist" => true,
      "position" => :rand.uniform(21) - 1,
      "permissions" => "0",
      "managed" => false,
      "mentionable" => true,
      "tags" => %{"integration_id" => random_snowflake()}
    }

    merge_opts(defaults, opts)
  end

  @spec application(keyword) :: map
  def application(opts \\ []) do
    team_id = random_snowflake()
    # The `team user` flag is enabled
    team_user = user(id: team_id, username: "team#{team_id}", flags: 1024, public_flags: 1024)

    defaults = %{
      "id" => team_id,
      "name" => random_hex(8),
      "icon" => random_hex(16),
      "description" => random_hex(32),
      "bot_public" => true,
      "bot_require_code_grant" => false,
      "owner" => team_user,
      "team" => team()
    }

    merge_opts(defaults, opts)
  end

  @spec team(keyword) :: map
  def team(opts \\ []) do
    owner_id = random_snowflake()

    defaults = %{
      "id" => random_snowflake(),
      "icon" => random_hex(8),
      "members" => [team_member(id: owner_id), team_member(), team_member()],
      "owner_user_id" => owner_id
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
    opts_map = Map.new(opts, fn {key, value} -> {Atom.to_string(key), value} end)

    Map.merge(defaults, opts_map)
  end
end