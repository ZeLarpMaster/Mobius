defmodule Mobius.Shard.Gatekeeper.Observing do
  @moduledoc false

  use GenServer

  alias Mobius.Shard.Gatekeeper

  @behaviour Gatekeeper

  # This Gatekeeper implementation lets everyone in immediately
  # And notifies the parent process with all the pids at each step

  @type state :: %{
          parent_pid: pid
        }

  @impl Gatekeeper
  @spec start_link([nil]) :: {:ok, pid}
  def start_link([nil]) do
    GenServer.start_link(__MODULE__, self())
  end

  @impl Gatekeeper
  @spec wait_until_can_identify(atom | pid) :: :ok
  def wait_until_can_identify(server) do
    GenServer.call(server, {:identifying, self()})
  end

  @impl Gatekeeper
  @spec ack_identified(atom | pid) :: :ok
  def ack_identified(server) do
    GenServer.call(server, {:identified, self()})
  end

  @impl GenServer
  @spec init(pid) :: {:ok, state()}
  def init(parent_pid) do
    state = %{
      parent_pid: parent_pid
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(request, _from, %{parent_pid: parent} = state) do
    send(parent, request)
    {:reply, :ok, state}
  end
end
