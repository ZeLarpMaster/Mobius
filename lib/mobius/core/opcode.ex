defmodule Mobius.Core.Opcode do
  @moduledoc false

  @spec heartbeat(integer) :: map
  def heartbeat(sequence_number) do
    sequence_number
    |> serialize(:heartbeat)
  end

  @spec identify(integer, integer, String.t()) :: map
  def identify(shard, shard_count, token) do
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
      "shard" => [shard, shard_count]
      # "intents" => 0, TODO
    }
    |> serialize(:identify)
  end

  @spec resume(String.t(), integer, String.t()) :: map
  def resume(session_id, sequence_number, token) do
    %{
      "token" => token,
      "session_id" => session_id,
      "seq" => sequence_number
    }
    |> serialize(:resume)
  end

  @spec request_guild_members(%{required(String.t()) => any}) :: map
  def request_guild_members(%{"nonce" => nonce} = payload) when byte_size(nonce) <= 32 do
    payload
    |> serialize(:request_guild_members)
  end

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
    -1 => :for_testing,
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
