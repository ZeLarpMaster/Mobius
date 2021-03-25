defmodule Mobius.Rest.Message do
  @moduledoc false

  alias Mobius.Models.Message
  alias Mobius.Models.Snowflake
  alias Mobius.Rest.Client
  alias Tesla.Multipart

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
          optional(:content) => String.t(),
          optional(:nonce) => String.t(),
          optional(:tts) => boolean,
          optional(:embed) => embed(),
          optional(:file) => {Multipart.part_value(), String.t()},
          optional(:allowed_mentions) => allowed_mentions(),
          optional(:message_reference) => message_reference()
        }

  @doc """
  Does the API call for "Create Message" and handles both `content-type`s as needed

  When sending a file, message params will be sent in `payload_json` as a json string.

  The file content can be `t:iodata/0` or a `Stream` of `t:binary/0`.
  If you want to send a file by path, use `File.stream!(path, [:read], 2048)` to get its content.

  If you want to use an uploaded image in your embeds,
  you can do so by using `"attachment://" <> filename` as the url.
  This only works if the filename has a proper image extension (such as `.png`, `.jpg`, etc.)
  """
  @spec send_message(Client.client(), Snowflake.t(), message_body()) :: Client.result(Message.t())
  def send_message(client, channel_id, %{file: {file, filename}} = body) do
    body = Map.drop(body, [:file])

    multipart =
      Multipart.new()
      |> Multipart.add_field("payload_json", Jason.encode!(body),
        headers: [{"content-type", "application/json"}]
      )
      |> Multipart.add_file_content(file, filename,
        name: "file",
        detect_content_type: true
      )

    client
    |> Tesla.post("/channels/:channel_id/messages", multipart,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(&Message.parse/1)
  end

  def send_message(client, channel_id, body) do
    client
    |> Tesla.post("/channels/:channel_id/messages", body,
      opts: [path_params: [channel_id: channel_id]]
    )
    |> Client.parse_response(&Message.parse/1)
  end
end
