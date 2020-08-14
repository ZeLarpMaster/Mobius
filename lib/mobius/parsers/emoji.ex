defmodule Mobius.Parsers.Emoji do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Parsers.Utils

  @spec parse_emoji(Utils.input(), Utils.path()) :: Utils.result()
  def parse_emoji(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      # :name may be nil for MESSAGE_REACTION_ADD and MESSAGE_REACTION_REMOVE
      {:required, :name, "name"},
      {:optional, :role_ids, {:via, "roles", Utils, :parse_snowflake}},
      {:optional, :user, {:via, "user", Parsers.User, :parse_user}},
      {:optional, :require_colons?, "require_colons"},
      {:optional, :managed?, "managed"},
      {:optional, :animated?, "animated"},
      {:optional, :available?, "available"}
    ]
    |> Utils.parse(value, path)
  end
end
