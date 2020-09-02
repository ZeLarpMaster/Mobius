defmodule Mobius.Services.Shard do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.Opcode
  alias Mobius.Core.ShardInfo

  @typep state :: %{
           seq: integer,
           session_id: String.t() | nil,
           token: String.t(),
           info: ShardInfo.t()
         }

  @typep payload :: %{
           op: integer,
           d: any,
           t: atom | nil,
           s: integer | nil
         }

  @spec get_sequence_number(ShardInfo.t()) :: integer
  def get_sequence_number(shard) do
    GenServer.call(via(shard), :get_seq)
  end

  @spec receive_payload(ShardInfo.t(), payload()) :: any
  def receive_payload(shard, payload) do
    GenServer.call(via(shard), {:payload, payload})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    %ShardInfo{} = shard_info = Keyword.fetch!(opts, :shard_info)

    state = %{
      seq: 0,
      session_id: nil,
      token: Keyword.fetch!(opts, :token),
      info: shard_info
    }

    # TODO: Link process to the other services
    # TODO: Figure out what to do when the other services die

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:payload, payload}, _from, state) do
    payload.op
    |> Opcode.opcode_to_name()
    |> process_payload(payload, state)
    |> reply()
  end

  def handle_call(:get_seq, _from, state) do
    {:reply, state.seq, state}
  end

  # Update the state and execute side effects depending on opcode
  defp process_payload(:dispatch, payload, state) do
    Logger.debug("Dispatching #{inspect(payload.t)}")
    # TODO: Side effects
    state
  end

  defp process_payload(:heartbeat, _payload, state) do
    # TODO: Send to socket
    state
  end

  defp via(%ShardInfo{} = shard), do: {:via, Registry, {Mobius.Registry.Shard, shard}}
  defp reply(state), do: {:reply, :ok, state}
end
