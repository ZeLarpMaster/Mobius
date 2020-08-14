defmodule Mobius.Parsers.Member do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Parsers.Utils

  @spec parse_member(Utils.input(), Utils.path()) :: Utils.result()
  def parse_member(value, path \\ nil) do
    [
      # :user is not there for MESSAGE_CREATE and MESSAGE_UPDATE events
      {:optional, :user, {:via, "user", Parsers.User, :parse_user}},
      {:required, :nickname, "nick"},
      {:required, :roles, {:via, "roles", Utils, :parse_snowflake}},
      {:required, :joined_at, {:via, "joined_at", Utils, :parse_iso8601}},
      {:optional, :premium_since, {:via, "premium_since", Utils, :parse_iso8601}},
      {:required, :deaf?, "deaf"},
      {:required, :mute?, "mute"}
    ]
    |> Utils.parse(value, path)
  end
end
