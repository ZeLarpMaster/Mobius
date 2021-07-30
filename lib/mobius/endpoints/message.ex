defmodule Mobius.Endpoint.Message do
  @moduledoc false

  alias Mobius.Endpoint

  @spec endpoints :: [Mobius.Endpoint.t()]
  def endpoints,
    do: [
      %Endpoint{
        name: :list_messages,
        url: "/channels/:channel_id/messages",
        method: :get,
        params: [:channel_id],
        opts: %{
          around: :snowflake,
          before: :snowflake,
          after: :snowflake,
          limit: {:integer, [min: 1, max: 100]}
        }
      }
    ]
end
