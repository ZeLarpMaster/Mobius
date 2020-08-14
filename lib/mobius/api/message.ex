defmodule Mobius.Api.Message do
  @moduledoc false

  alias Mobius.Parsers
  alias Mobius.Api.Client
  alias Mobius.Models.Snowflake

  @spec list_messages(Client.client(), Snowflake.t(), keyword) :: {:ok, list} | Client.error()
  def list_messages(client, channel_id, params) do
    position_params = Keyword.take(params, [:around, :before, :after])

    if length(position_params) > 1 do
      raise ArgumentError, message: ":around, :before, and :after are mutually exclusive"
    end

    Tesla.get(client, "/channels/:channel_id/messages",
      query: Keyword.take(params, [:limit]) ++ position_params,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(Parsers.Message, :parse_message)
    |> reverse_if_params(params)
  end

  @spec get_message(Client.client(), Snowflake.t(), Snowflake.t()) :: {:ok, map} | Client.error()
  def get_message(client, channel_id, message_id) do
    Tesla.get(client, "/channels/:channel_id/messages/:message_id",
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.parse_response(Parsers.Message, :parse_message)
  end

  @spec create_message(Client.client(), Snowflake.t(), keyword) :: {:ok, map} | Client.error()
  def create_message(client, channel_id, params) do
    body =
      %{
        "content" => Keyword.get(params, :content),
        "nonce" => Keyword.get(params, :nonce),
        "tts" => Keyword.get(params, :tts),
        "file" => Keyword.get(params, :file),
        "embed" => Keyword.get(params, :embed),
        "payload_json" => Keyword.get(params, :payload_json),
        "allowed_mentions" => Keyword.get(params, :allowed_mentions, %{"parse" => []})
      }
      |> Enum.to_list()
      |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
      |> Map.new()

    unless is_map_key(body, "content") or is_map_key(body, "embed") do
      raise ArgumentError, message: "A message must have at least one of content or embed"
    end

    # TODO: Sanitize "content" to remove invalid unicode values

    Tesla.post(client, "/channels/:channel_id/messages", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(Parsers.Message, :parse_message)
  end

  @spec edit_message(Client.client(), Snowflake.t(), Snowflake.t(), keyword) ::
          {:ok, map} | Client.error()
  def edit_message(client, channel_id, message_id, params) do
    body =
      params
      |> Keyword.take([:content, :embed, :flags])
      |> Map.new()

    Tesla.patch(client, "/channels/:channel_id/messages/:message_id", body,
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.parse_response(Parsers.Message, :parse_message)
  end

  @spec delete_message(Client.client(), Snowflake.t(), Snowflake.t()) :: :ok | Client.error()
  def delete_message(client, channel_id, message_id) do
    Tesla.delete(client, "/channels/:channel_id/messages/:message_id",
      opts: [path_params: [channel_id: channel_id, message_id: message_id]]
    )
    |> Client.check_empty_response()
  end

  @spec bulk_delete_messages(Client.client(), Snowflake.t(), [Snowflake.t()]) ::
          :ok | Client.error()
  def bulk_delete_messages(client, channel_id, message_ids) when length(message_ids) in 2..100 do
    body = %{"messages" => message_ids}

    Tesla.post(client, "/channels/:channel_id/messages/bulk-delete", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.check_empty_response()
  end

  defp reverse_if_params({:ok, messages}, params) do
    oldest_first? = Keyword.get(params, :oldest_first, false)

    case oldest_first? do
      true -> {:ok, Enum.reverse(messages)}
      false -> {:ok, messages}
    end
  end

  defp reverse_if_params(value, _params), do: value
end
