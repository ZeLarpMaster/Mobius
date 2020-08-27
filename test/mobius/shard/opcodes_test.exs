defmodule Mobius.Shard.OpcodesTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures

  alias Mobius.Models.Intents
  alias Mobius.Shard.{Opcodes, GatewayState}

  describe "heartbeat/1" do
    test "serializes with the right opcode" do
      %GatewayState{}
      |> Opcodes.heartbeat()
      |> assert_opcode(:heartbeat)
    end

    test "serializes with the right data" do
      num = :rand.uniform(1000)

      data =
        %GatewayState{seq: num}
        |> Opcodes.heartbeat()
        |> deserialize()
        |> elem(1)

      assert data == num
    end
  end

  describe "identify/1" do
    test "serializes with the right opcode" do
      %GatewayState{intents: Intents.all_intents()}
      |> Opcodes.identify()
      |> assert_opcode(:identify)
    end

    test "serializes with the right data" do
      {family, name} = :os.type()
      os_value = Atom.to_string(family) <> " " <> Atom.to_string(name)
      shard = 1
      shard_count = 2
      token = random_hex(8)
      intents = Intents.all_intents()

      expected_value = %{
        "token" => token,
        "properties" => %{
          "$os" => os_value,
          "$browser" => "Mobius",
          "$device" => "Mobius"
        },
        "compress" => false,
        "shard" => [shard, shard_count],
        "intents" => Intents.intents_to_integer(intents)
      }

      data =
        %GatewayState{shard_num: shard, shard_count: shard_count, token: token, intents: intents}
        |> Opcodes.identify()
        |> deserialize()
        |> elem(1)

      assert data == expected_value
    end
  end

  describe "resume/1" do
    test "serializes with the right opcode" do
      %GatewayState{}
      |> Opcodes.resume()
      |> assert_opcode(:resume)
    end

    test "serializes with the right data" do
      num = :rand.uniform(1000)
      session_id = "some long weird string"
      token = random_hex(8)

      data =
        %GatewayState{seq: num, session_id: session_id, token: token}
        |> Opcodes.resume()
        |> deserialize()
        |> elem(1)

      assert data == %{"session_id" => session_id, "seq" => num, "token" => token}
    end
  end

  describe "request_guild_members/1" do
    test "has a limit of 32 bytes on the payload's nonce" do
      nonce_too_long = String.duplicate("a", 33)
      assert byte_size(nonce_too_long) > 32

      assert_raise(FunctionClauseError, fn ->
        Opcodes.request_guild_members(%{"nonce" => nonce_too_long})
      end)
    end

    test "serializes with the right opcode" do
      %{"nonce" => "a nonce"}
      |> Opcodes.request_guild_members()
      |> assert_opcode(:request_guild_members)
    end

    test "serializes with the payload as data" do
      payload = %{
        "nonce" => "a nonce",
        "guild_id" => random_snowflake(),
        "user_ids" => random_snowflake()
      }

      data =
        payload
        |> Opcodes.request_guild_members()
        |> deserialize()
        |> elem(1)

      assert data == payload
    end
  end

  describe "update_status/2" do
    test "sets default values" do
      payload = %{
        "status" => "online",
        "afk" => false,
        "game" => nil,
        "since" => nil
      }

      data =
        %{}
        |> Opcodes.update_status()
        |> deserialize()
        |> elem(1)

      assert data == payload
    end

    test "serializes to the right opcode" do
      %{}
      |> Opcodes.update_status()
      |> assert_opcode(:presence_update)
    end
  end

  describe "update_voice_status/2" do
    test "can't be called without a guild_id" do
      assert_raise FunctionClauseError, fn ->
        Opcodes.update_voice_status(%{})
      end
    end

    test "sets default values" do
      payload = %{
        "guild_id" => random_snowflake(),
        "channel_id" => nil,
        "self_mute" => false,
        "self_deaf" => false
      }

      data =
        %{"guild_id" => payload["guild_id"]}
        |> Opcodes.update_voice_status()
        |> deserialize()
        |> elem(1)

      assert data == payload
    end

    test "serializes to the right opcode" do
      %{"guild_id" => random_snowflake()}
      |> Opcodes.update_voice_status()
      |> assert_opcode(:voice_status_update)
    end
  end

  describe "serialize/1" do
    test "serializes with the given opcode" do
      opcode = random_opcode()

      Opcodes.serialize(nil, opcode)
      |> assert_opcode(opcode)
    end

    test "serializes with the given data" do
      num = :rand.uniform(1000)

      data =
        num
        |> Opcodes.serialize(random_opcode())
        |> deserialize()
        |> elem(1)

      assert data == num
    end
  end

  defp random_opcode do
    Opcodes.valid_opcodes()
    |> Enum.random()
    |> Opcodes.opcode_to_name()
  end

  defp assert_opcode(message, opcode_name) do
    opcode =
      message
      |> deserialize()
      |> elem(0)

    assert opcode == Opcodes.name_to_opcode(opcode_name)
  end

  defp deserialize(payload) do
    {payload["op"], payload["d"]}
  end
end
