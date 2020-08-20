defmodule Mobius.Shard.Opcodes do
  @moduledoc false

  require Logger

  alias Mobius.Shard.GatewayState

  # Gateway payloads
  @spec heartbeat(GatewayState.t()) :: map
  def heartbeat(%GatewayState{seq: sequence_number}) do
    sequence_number
    |> serialize(:heartbeat)
  end

  @spec identify(GatewayState.t()) :: map
  def identify(%GatewayState{} = state) do
    {family, name} = :os.type()
    intents = Mobius.Intents.intents_to_integer(state.intents)

    Logger.debug(
      "Intended events for #{inspect(state.intents)} (#{intents}): " <>
        "#{inspect(Mobius.Intents.events_for_intents(state.intents))}"
    )

    %{
      "token" => state.token,
      "properties" => %{
        "$os" => Atom.to_string(family) <> " " <> Atom.to_string(name),
        "$browser" => "Mobius",
        "$device" => "Mobius"
      },
      # Compression here can't be enabled because we're using ETF
      "compress" => false,
      "shard" => [state.shard_num, state.shard_count],
      "intents" => intents
    }
    |> serialize(:identify)
  end

  @spec resume(GatewayState.t()) :: map
  def resume(%GatewayState{session_id: session_id, seq: last_sequence, token: token}) do
    %{
      "token" => token,
      "session_id" => session_id,
      "seq" => last_sequence
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
  @gateway_opcodes %{
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
  @gateway_opcodes_inverse @gateway_opcodes |> Map.to_list() |> Map.new(fn {k, v} -> {v, k} end)

  @spec opcode_to_name(integer) :: atom
  def opcode_to_name(opcode) when is_integer(opcode) do
    Map.fetch!(@gateway_opcodes, opcode)
  end

  @spec name_to_opcode(atom) :: integer
  def name_to_opcode(name) when is_atom(name) do
    Map.fetch!(@gateway_opcodes_inverse, name)
  end

  @spec valid_opcodes :: [integer]
  def valid_opcodes, do: Map.keys(@gateway_opcodes)
end
