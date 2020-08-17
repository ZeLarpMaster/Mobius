defmodule Mobius.Shard.MemberRequest do
  @moduledoc false

  # A module for managing everything about guild member requests and their chunks
  # This basically helps the gateway organize the received chunks into a Stream

  # TODO: What to do with the not_founds?
  # TODO: Presences are currently unused

  require Logger

  alias Mobius.TimeoutError

  @timeout Application.compile_env(:mobius, :member_request_timeout_ms, 10_000)

  # Request specific members in specific guilds
  def request_with_ids(_, _, user_ids, _) when length(user_ids) > 100 do
    raise "Cannot ask for more than 100 members"
  end

  def request_with_ids(gateway, guild_ids, user_ids, presences?) do
    payload = %{
      "guild_id" => guild_ids,
      "user_ids" => user_ids,
      "presences" => presences?
    }

    make_stream(gateway, payload)
  end

  def request_with_prefix(_, _, _, limit, _) when limit > 100 do
    raise "Cannot ask for more than 100 members"
  end

  def request_with_prefix(_, _, prefix, limit, _) when prefix != "" and limit == 0 do
    raise "Cannot request for all members when using a prefix"
  end

  def request_with_prefix(gateway, guild_ids, name_prefix, limit, presences?) do
    payload = %{
      "guild_id" => guild_ids,
      "query" => name_prefix,
      "limit" => limit,
      "presences" => presences?
    }

    make_stream(gateway, payload)
  end

  def make_stream(gateway, payload) do
    # Start a process which keeps track of the chunks received
    {:ok, pid} = Task.start_link(&chunk_holder_task/0)
    # Tell the Socket it can make the request and keep the nonce to tell it when we're done
    GenServer.call(gateway, {:member_request, pid, payload})
    |> case do
      {:error, :ratelimited} ->
        # Stop the process to cleanup
        send(pid, :shutdown)
        {:error, :ratelimited}

      nonce ->
        Stream.resource(
          fn -> send(pid, {:set_consumer, self()}) end,
          fn _ -> wait_for_chunk() end,
          fn _ ->
            # Tell the task to shutdown in case we timed out
            send(pid, :shutdown)
            # Tell the gateway the nonce is complete
            GenServer.call(gateway, {:request_complete, nonce})
          end
        )
    end
  end

  defp wait_for_chunk do
    receive do
      :eof -> {:halt, nil}
      {:members_chunk, members} -> {members, nil}
    after
      @timeout -> raise TimeoutError, message: "Timed out while waiting for member chunks"
    end
  end

  def chunk_holder_task(consumer_pid \\ nil, next_chunk \\ 0, chunks \\ %{}, chunk_count \\ nil) do
    receive do
      {:chunk, chunk} ->
        index = chunk.chunk_index
        chunk_count = chunk.chunk_count
        members = Enum.map(chunk.members, &Map.put(&1, :guild_id, chunk.guild_id))
        chunks = Map.put(chunks, index, members)

        {next_chunk, chunks} = send_chunks(consumer_pid, next_chunk, chunks)

        if next_chunk == chunk.chunk_count do
          send(consumer_pid, :eof)
          :ok
        else
          chunk_holder_task(consumer_pid, next_chunk, chunks, chunk_count)
        end

      {:set_consumer, pid} ->
        {next_chunk, chunks} = send_chunks(pid, next_chunk, chunks)

        if next_chunk == chunk_count do
          send(pid, :eof)
          :ok
        else
          chunk_holder_task(pid, next_chunk, chunks, chunk_count)
        end

      :shutdown ->
        :shutdown
    end
  end

  defp send_chunks(nil, next_chunk, chunks), do: {next_chunk, chunks}

  defp send_chunks(consumer_pid, next_chunk, chunks) do
    {members, chunks} = Map.pop(chunks, next_chunk, nil)

    if members == nil do
      {next_chunk, chunks}
    else
      send(consumer_pid, {:members_chunk, members})
      send_chunks(consumer_pid, next_chunk + 1, chunks)
    end
  end
end
