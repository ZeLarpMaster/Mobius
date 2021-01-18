defmodule Mobius.Models.User do
  @moduledoc """
  Struct for Discord's User

  Relevant documentation: https://discord.com/developers/docs/resources/user#user-object
  """

  import Mobius.Models.Utils

  alias Mobius.Core.Bitflags
  alias Mobius.Models.Snowflake

  defstruct [
    :id,
    :username,
    :discriminator,
    :avatar,
    :bot,
    :system,
    :mfa_enabled,
    :locale,
    :verified,
    :email,
    :flags,
    :premium_type,
    :public_flags
  ]

  @flags [
    :discord_employee,
    :partnered_server_owner,
    :hypesquad_events,
    :bug_hunter_level_1,
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
    :bug_hunter_level_2,
    nil,
    :verified_bot,
    :early_verified_bot_developer
  ]

  @type flag ::
          :discord_employee
          | :partnered_server_owner
          | :hypesquad_events
          | :bug_hunter_level_1
          | :house_bravery
          | :house_brilliance
          | :house_balance
          | :early_supporter
          | :team_user
          | :system
          | :bug_hunter_level_1
          | :verified_bot
          | :early_verified_bot_developer
  @type flags :: MapSet.t(flag())
  @type premium_type :: :none | :nitro_classic | :nitro

  @type partial :: %__MODULE__{
          id: Snowflake.t(),
          username: String.t(),
          discriminator: String.t(),
          avatar: String.t() | nil
        }

  @type t :: %__MODULE__{
          id: Snowflake.t(),
          username: String.t(),
          discriminator: String.t(),
          avatar: String.t() | nil,
          bot: boolean,
          system: boolean,
          mfa_enabled: boolean,
          locale: String.t(),
          verified: boolean,
          email: String.t(),
          flags: flags(),
          premium_type: premium_type(),
          public_flags: flags()
        }

  @doc "Parses the given term into a `t:t()` if possible; returns nil otherwise"
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :id, &Snowflake.parse/1)
    |> add_field(map, :username)
    |> add_field(map, :discriminator)
    |> add_field(map, :avatar)
    |> add_field(map, :bot)
    |> add_field(map, :system)
    |> add_field(map, :mfa_enabled)
    |> add_field(map, :locale)
    |> add_field(map, :verified)
    |> add_field(map, :email)
    |> add_field(map, :flags, &parse_flags/1)
    |> add_field(map, :premium_type, &parse_premium_type/1)
    |> add_field(map, :public_flags, &parse_flags/1)
  end

  def parse(_), do: nil

  defp parse_premium_type(0), do: :none
  defp parse_premium_type(1), do: :nitro_classic
  defp parse_premium_type(2), do: :nitro
  defp parse_premium_type(_), do: nil

  defp parse_flags(flags) when is_integer(flags), do: Bitflags.parse_bitflags(flags, @flags)
  defp parse_flags(_flags), do: nil
end
