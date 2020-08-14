defmodule Mobius.Samples.Message do
  @moduledoc false

  import Mobius.Fixtures

  alias Mobius.Samples

  @spec raw_message(:full) :: map
  def raw_message(:full) do
    %{
      "id" => "#{random_snowflake()}",
      "channel_id" => "#{random_snowflake()}",
      "guild_id" => "#{random_snowflake()}",
      "author" => Samples.User.raw_user(:minimal),
      "content" => random_hex(16),
      "timestamp" => Samples.Other.iso8601(),
      "edited_timestamp" => Samples.Other.iso8601(),
      "tts" => false,
      "mention_everyone" => false,
      "mentions" => [],
      "mention_roles" => [],
      "mention_channels" => [],
      "attachments" => [],
      "embeds" => [],
      "reactions" => [],
      "nonce" => random_hex(16),
      "pinned" => false,
      "webhook_id" => "#{random_snowflake()}",
      "type" => 0,
      "flags" => 4
    }
  end
end
