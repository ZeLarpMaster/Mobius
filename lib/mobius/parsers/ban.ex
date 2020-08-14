defmodule Mobius.Parsers.Ban do
  @moduledoc false

  alias Mobius.Parsers.Utils
  alias Mobius.Parsers.User

  @spec parse_ban(Utils.input(), Utils.path()) :: Utils.result()
  def parse_ban(value, path \\ nil) do
    [
      {:required, :reason, "reason"},
      {:required, :user, {:via, "user", User, :parse_user}}
    ]
    |> Utils.parse(value, path)
  end
end
