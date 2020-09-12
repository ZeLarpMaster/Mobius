defmodule MessageFetch do
  @moduledoc false

  alias Mobius.Core.Rest.Channel
  alias Mobius.Core.Rest.Message

  @guild_id "355384548671881216" |> String.to_integer()

  def start do
    with client <- GenServer.call(Mobius.Services.Bot, :get_client) do
      Channel.list_guild_channels(client, @guild_id)
      |> filter_channels()
      |> Enum.map(&{&1, start_task(client, &1)})
      |> Enum.map(fn {c_id, task} -> {c_id, Task.await(task)} end)
      |> Map.new()
      |> Jason.encode!()
      |> write_to_file("./consensus.json")
    end
  end

  defp write_to_file(content, filepath) do
    File.write!(filepath, content, [:binary])
  end

  defp filter_channels({:ok, channels}) do
    channels
    |> Enum.filter(fn %{"type" => type} -> type == 0 end)
    |> Enum.map(fn %{"id" => id} -> String.to_integer(id) end)
  end

  defp start_task(client, channel_id) do
    Task.async(fn ->
      list_messages(client, channel_id)
      |> Enum.map(fn msg -> msg["content"] end)
      |> Enum.flat_map(&String.split/1)
      |> Enum.frequencies()
    end)
  end

  defp list_messages(client, channel_id) do
    Stream.resource(
      fn ->
        {:ok, messages} = Message.list_messages(client, channel_id, limit: 5)
        messages
      end,
      fn
        [] ->
          {:halt, []}

        [msg] ->
          Process.sleep(500)

          {:ok, msgs} =
            Message.list_messages(client, channel_id,
              limit: 5,
              before: String.to_integer(msg["id"])
            )

          if length(msgs) == 5 do
            {[msg], msgs}
          else
            {msgs, []}
          end

        [msg | msgs] ->
          {[msg], msgs}
      end,
      fn _ -> nil end
    )
  end
end
