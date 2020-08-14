defmodule Mobius.Parsers.Role do
  @moduledoc false

  alias Mobius.Parsers.Utils

  @spec parse_role(Utils.input(), Utils.path()) :: Utils.result()
  def parse_role(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "name"},
      {:required, :color, "color"},
      {:required, :hoisted?, "hoist"},
      {:required, :position, "position"},
      {:required, :permissions, "permissions"},
      {:required, :managed?, "managed"},
      {:required, :mentionable?, "mentionable"}
    ]
    |> Utils.parse(value, path)
  end
end
