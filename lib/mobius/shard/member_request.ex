defmodule Mobius.Shard.MemberRequest do
  @moduledoc false

  # A module for managing everything about guild member requests and their chunks
  # This basically helps the gateway organize the received chunks into a Stream

  # Relevant documentation: https://discord.com/developers/docs/topics/gateway#request-guild-members

  # The docs say guild_id can be a snowflake or an array of snowflakes, but
  # because we're using intents, it can only be a single snowflake
  # It also says "snowflake", but really it has to be a string otherwise it never sends chunks

  # TODO: What to do with the not_founds?
  # TODO: Presences are currently unused
  # TODO: Figure out a way to timeout the chunk task if the stream is never consumed

  require Logger

  alias Mobius.TimeoutError
  alias Mobius.Models.Intents

  @timeout Application.compile_env(:mobius, :member_request_timeout_ms, 10_000)

  @type errors :: {:error, :ratelimited | String.t()}
  @type out :: Stream.t() | errors()

  # Request specific members in specific guilds
  @spec request_with_ids(GenServer.server(), String.t(), list(String.t()), boolean) :: out()
  def request_with_ids(_, _, user_ids, _) when length(user_ids) > 100 do
    raise "Cannot ask for more than 100 members"
  end

  def request_with_ids(gateway, guild_id, user_ids, presences?) do
    payload = %{
      "guild_id" => guild_id,
      "user_ids" => user_ids,
      "presences" => presences?
    }

    make_stream(gateway, payload)
  end

  @spec request_with_prefix(GenServer.server(), String.t(), String.t(), integer, boolean) :: out()
  def request_with_prefix(_, _, _, limit, _) when limit > 100 do
    raise "Cannot ask for more than 100 members"
  end

  def request_with_prefix(_, _, prefix, limit, _) when prefix != "" and limit == 0 do
    raise "Cannot request for all members when using a prefix"
  end

  def request_with_prefix(gateway, guild_id, name_prefix, limit, presences?) do
    payload = %{
      "guild_id" => guild_id,
      "query" => name_prefix,
      "limit" => limit,
      "presences" => presences?
    }

    make_stream(gateway, payload)
  end

  @spec check_intents(map, Intents.intents()) :: :ok | {:error, String.t()}
  def check_intents(payload, intents) do
    cond do
      payload["presences"] and not MapSet.member?(intents, :guild_presences) ->
        {:error, "Cannot request presences without the :guild_presences intent"}

      payload["query"] == "" and not MapSet.member?(intents, :guild_members) ->
        {:error, "Cannot request all members (empty prefix) without the :guild_members intent"}

      true ->
        :ok
    end
  end

  @spec make_stream(GenServer.server(), map) :: out()
  def make_stream(gateway, payload) do
    # Start a process which keeps track of the chunks received
    {:ok, pid} = Task.start_link(&chunk_holder_task/0)
    # Tell the Socket it can make the request and keep the nonce to tell it when we're done
    GenServer.call(gateway, {:member_request, pid, payload})
    |> case do
      {:error, error} ->
        # Stop the process to cleanup
        send(pid, :shutdown)
        {:error, error}

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
