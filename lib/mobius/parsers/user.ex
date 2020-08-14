defmodule Mobius.Parsers.User do
  @moduledoc false

  alias Mobius.Parsers.Utils

  @spec parse_user(Utils.input(), Utils.path()) :: Utils.result()
  def parse_user(value, path \\ nil) do
    [
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "username"},
      {:required, :discriminator, "discriminator"},
      {:required, :avatar, "avatar"},
      {:optional, :bot?, "bot"},
      {:optional, :system?, "system"},
      {:optional, :mfa?, "mfa_enabled"},
      {:optional, :locale, "locale"},
      {:optional, :verified?, "verified"},
      {:optional, :email, "email"},
      {:optional, :flags, {:via, "flags", __MODULE__, :parse_user_flags}},
      {:optional, :premium_type, {:via, "premium_type", __MODULE__, :parse_user_premium}},
      {:optional, :public_flags, {:via, "public_flags", __MODULE__, :parse_user_flags}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_user_flags(integer, Utils.path()) :: [atom]
  def parse_user_flags(num, _path), do: Utils.parse_flags(num, user_flags())

  @spec parse_user_premium(integer, Utils.path()) :: atom | integer
  def parse_user_premium(0, _path), do: :none
  def parse_user_premium(1, _path), do: :nitro_classic
  def parse_user_premium(2, _path), do: :nitro
  def parse_user_premium(type, _path), do: type

  @spec user_flags :: [atom | nil]
  def user_flags do
    [
      :discord_employee,
      :discord_partner,
      :hypesquad_events,
      :bug_hunter_level1,
      nil,
      nil,
      :house_bravery,
      :house_brilliance,
      :house_balance,
      :early_supporter,
      :team_user,
      nil,
      :system,
      nil,
      :bug_hunter_level2,
      nil,
      :verified_bot,
      :verified_bot_developer
    ]
  end
end
