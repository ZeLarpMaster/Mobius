defmodule Mobius.Core.Opcode do
  @moduledoc false

  alias Mobius.Core.ShardInfo

  @doc """
  Creates a heartbeat payload

      iex> heartbeat(42)["op"] == name_to_opcode(:heartbeat)
      true
      iex> heartbeat(42)["d"]
      42
  """
  @spec heartbeat(integer) :: map
  def heartbeat(sequence_number) do
    sequence_number
    |> serialize(:heartbeat)
  end

  @doc """
  Creates an identify payload

      iex> shard = Mobius.Core.ShardInfo.new(number: 0, count: 1)
      iex> identify(shard, "a token")["op"] == name_to_opcode(:identify)
      true
      iex> payload = identify(shard, "a token")["d"]
      iex> payload["token"]
      "a token"
      iex> payload["compress"]
      false
      iex> payload["shard"] == Mobius.Core.ShardInfo.to_list(shard)
      true
      iex> String.length(payload["properties"]["$os"]) > 1
      true
      iex> payload["properties"]["$browser"]
      "Mobius"
      iex> payload["properties"]["$device"]
      "Mobius"
  """
  @spec identify(ShardInfo.t(), String.t()) :: map
  def identify(shard, token) do
    {family, name} = :os.type()

    %{
      "token" => token,
      "properties" => %{
        "$os" => Atom.to_string(family) <> " " <> Atom.to_string(name),
        "$browser" => "Mobius",
        "$device" => "Mobius"
      },
      # Compression here can't be enabled because we're using ETF
      "compress" => false,
      "shard" => ShardInfo.to_list(shard)
      # "intents" => 0, TODO
    }
    |> serialize(:identify)
  end

  @doc """
  Creates a resume payload

      iex> resume("Session", 42, "Token")["op"] == name_to_opcode(:resume)
      true
      iex> resume("Session", 42, "Token")["d"]
      %{"token" => "Token", "session_id" => "Session", "seq" => 42}
  """
  @spec resume(String.t(), integer, String.t()) :: map
  def resume(session_id, sequence_number, token) do
    %{
      "token" => token,
      "session_id" => session_id,
      "seq" => sequence_number
    }
    |> serialize(:resume)
  end

  @doc """
  Creates a guild member request payload

  The nonce given must have a byte_size of 32 or less

      iex> request_guild_members(%{"nonce" => String.duplicate("a", 33)})
      ** (FunctionClauseError) no function clause matching in Mobius.Core.Opcode.request_guild_members/1

      iex> data = %{"nonce" => "a", "guild_id" => 123}
      iex> payload = request_guild_members(data)
      iex> payload["op"] == name_to_opcode(:request_guild_members)
      true
      iex> payload["d"] == data
      true
  """
  @spec request_guild_members(%{required(String.t()) => any}) :: map
  def request_guild_members(%{"nonce" => nonce} = payload) when byte_size(nonce) <= 32 do
    payload
    |> serialize(:request_guild_members)
  end

  @doc """
  Creates a status update payload

      iex> update_status(%{})["op"] == name_to_opcode(:presence_update)
      true
      iex> update_status(%{})["d"]
      %{"status" => "online", "afk" => false, "game" => nil, "since" => nil}
      iex> update_status(%{"status" => "idle"})["d"]
      %{"status" => "idle", "afk" => false, "game" => nil, "since" => nil}
      iex> update_status(%{"afk" => true})["d"]
      %{"status" => "online", "afk" => true, "game" => nil, "since" => nil}
      iex> update_status(%{"game" => %{}})["d"]
      %{"status" => "online", "afk" => false, "game" => %{}, "since" => nil}
      iex> update_status(%{"since" => 12345})["d"]
      %{"status" => "online", "afk" => false, "game" => nil, "since" => 12345}
      iex> update_status(%{"status" => "idle", "afk" => true, "game" => %{}, "since" => 12345})["d"]
      %{"status" => "idle", "afk" => true, "game" => %{}, "since" => 12345}
  """
  @spec update_status(map) :: map
  def update_status(status) do
    %{
      "status" => "online",
      "afk" => false,
      "game" => nil,
      "since" => nil
    }
    |> Map.merge(status)
    |> serialize(:presence_update)
  end

  @doc """
  Creates a voice status update payload

      iex> update_voice_status(%{"guild_id" => 123})["op"] == name_to_opcode(:voice_status_update)
      true
      iex> update_voice_status(%{"guild_id" => 123})["d"]
      %{"guild_id" => 123, "channel_id" => nil, "self_mute" => false, "self_deaf" => false}
      iex> update_voice_status(%{"guild_id" => 123, "channel_id" => 124})["d"]
      %{"guild_id" => 123, "channel_id" => 124, "self_mute" => false, "self_deaf" => false}
      iex> update_voice_status(%{"guild_id" => 123, "self_mute" => true, "self_deaf" => true})["d"]
      %{"guild_id" => 123, "channel_id" => nil, "self_mute" => true, "self_deaf" => true}
  """
  @spec update_voice_status(map) :: map
  def update_voice_status(%{"guild_id" => guild_id} = status) when guild_id != nil do
    %{
      "channel_id" => nil,
      "self_mute" => false,
      "self_deaf" => false
    }
    |> Map.merge(status)
    |> serialize(:voice_status_update)
  end

  @spec serialize(any, atom) :: map
  def serialize(data, opcode_name) do
    %{"op" => name_to_opcode(opcode_name), "d" => data}
  end

  # Opcode translation
  # Source: https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes
  @opcodes %{
    0 => :dispatch,
    1 => :heartbeat,
    2 => :identify,
    3 => :presence_update,
    4 => :voice_status_update,
    6 => :resume,
    7 => :reconnect,
    8 => :request_guild_members,
    9 => :invalid_session,
    10 => :hello,
    11 => :heartbeat_ack
  }

  @spec valid_opcodes :: [integer]
  def valid_opcodes, do: unquote(Enum.map(@opcodes, fn {k, _v} -> k end))

  @spec name_to_opcode(atom) :: integer
  @spec opcode_to_name(integer) :: atom
  for {opcode, name} <- @opcodes do
    def name_to_opcode(unquote(name)), do: unquote(opcode)
    def opcode_to_name(unquote(opcode)), do: unquote(name)
  end
end
