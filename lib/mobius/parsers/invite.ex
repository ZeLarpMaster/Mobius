defmodule Mobius.Parsers.Invite do
  @moduledoc false

  alias Mobius.Parsers.Utils
  alias Mobius.Parsers.Channel
  alias Mobius.Parsers.Guild
  alias Mobius.Parsers.User

  @spec parse_invite(Utils.input(), Utils.path()) :: Utils.result()
  def parse_invite(value, path \\ nil) do
    [
      {:required, :code, "code"},
      {:required, :channel, {:via, "channel", Channel, :parse_channel}},
      {:optional, :guild, {:via, "guild", __MODULE__, :parse_invite_guild}},
      {:optional, :inviter, {:via, "inviter", User, :parse_user}},
      {:optional, :target_user, {:via, "target_user", User, :parse_user}},
      {:optional, :target_user_type, {:via, "target_user_type", __MODULE__, :parse_user_type}},
      {:optional, :approximate_presence_count, "approximate_presence_count"},
      {:optional, :approximate_member_count, "approximate_member_count"},
      # invite metadata
      {:optional, :uses, "uses"},
      {:optional, :max_uses, "max_uses"},
      {:optional, :max_age, "max_age"},
      {:optional, :temporary?, "temporary"},
      {:optional, :created_at, {:via, "created_at", Utils, :parse_iso8601}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_invite_guild(Utils.input(), Utils.path()) :: Utils.result()
  def parse_invite_guild(value, path \\ nil) do
    [
      {:required, :banner, "banner"},
      {:required, :description, "description"},
      {:required, :features, {:raw, "features", Guild, :parse_features}},
      {:required, :icon, "icon"},
      {:required, :id, {:via, "id", Utils, :parse_snowflake}},
      {:required, :name, "name"},
      {:required, :splash, "splash"},
      {:required, :vanity_url_code, "vanity_url_code"},
      {:required, :verification_level,
       {:via, "verification_level", Guild, :parse_verification_level}}
    ]
    |> Utils.parse(value, path)
  end

  @spec parse_user_type(integer, Utils.path()) :: atom | integer
  def parse_user_type(1, _path), do: :stream
  def parse_user_type(value, _path), do: value
end
