defmodule Mobius.Rest.Message do
  @moduledoc false

  alias Mobius.Models.Message
  alias Mobius.Models.Snowflake
  alias Mobius.Rest.Client

  @type embed :: %{
          optional(:title) => String.t(),
          optional(:description) => String.t(),
          optional(:url) => String.t(),
          optional(:timestamp) => DateTime.t(),
          optional(:color) => 0..16_777_215,
          optional(:footer) => %{optional(:text) => String.t(), optional(:icon_url) => String.t()},
          optional(:image) => %{url: String.t()},
          optional(:thumbnail) => %{url: String.t()},
          optional(:author) => %{
            optional(:name) => String.t(),
            optional(:url) => String.t(),
            optional(:icon_url) => String.t()
          },
          optional(:fields) => [
            %{
              required(:name) => String.t(),
              required(:value) => String.t(),
              optional(:inline) => boolean
            }
          ]
        }

  @type allowed_mentions :: %{
          optional(:parse) => [:roles | :users | :everyone],
          optional(:roles) => [Snowflake.t()],
          optional(:users) => [Snowflake.t()],
          optional(:replied_user) => boolean
        }

  @type message_reference :: %{
          required(:message_id) => Snowflake.t(),
          optional(:channel_id) => Snowflake.t(),
          optional(:guild_id) => Snowflake.t(),
          optional(:fail_if_not_exists) => boolean
        }

  @type message_body :: %{
          content: String.t(),
          nonce: String.t(),
          tts: boolean,
          embed: embed(),
          allowed_mentions: allowed_mentions(),
          message_reference: message_reference()
        }

  @doc """
  Does the API call for "Create Message"'s with `content-type: application/json`

  This doesn't allow sending files since allowing both in the same function would make it very
  complicated with little added value. Instead sending files is implemented in `send_file/4`.
  """
  @spec send_message(Client.client(), Snowflake.t(), message_body()) :: Client.result(Message.t())
  def send_message(client, channel_id, body) do
    client
    |> Tesla.post("/channels/:channel_id/messages", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(&Message.parse/1)
  end
end
