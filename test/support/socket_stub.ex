defmodule Mobius.Stubs.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Mobius.Core.ShardInfo
  alias Mobius.Services.Socket

  @behaviour Socket

  @type msg :: :close | {:msg, any}

  @type state :: %{
          url: String.t(),
          query: String.t(),
          shard: ShardInfo.t(),
          test_pid: pid | nil,
          messages: [msg()]
        }

  # Socket callbacks
  @impl Socket
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl Socket
  @spec send_message(term, GenServer.server()) :: :ok
  def send_message(message, socket) do
    GenServer.cast(socket, {:send, message})
  end

  @impl Socket
  @spec close(GenServer.server()) :: :ok
  def close(socket) do
    GenServer.call(socket, :close)
  end

  # Stub API
  @spec set_owner(GenServer.server()) :: :ok
  def set_owner(socket) do
    GenServer.call(socket, {:set_test, self()})
  end

  @spec has_closed?(GenServer.server()) :: boolean
  def has_closed?(socket) do
    GenServer.call(socket, :has_closed?)
  end

  @spec has_message?(GenServer.server(), (any -> boolean)) :: boolean
  def has_message?(socket, func) when is_function(func, 1) do
    GenServer.call(socket, {:has_message?, func})
  end

  # GenServer and :gun stuff
  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    state = %{
      url: Keyword.fetch!(opts, :url),
      query: Keyword.fetch!(opts, :query),
      shard: Keyword.fetch!(opts, :shard),
      test_pid: nil,
      messages: []
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:send, payload}, state) do
    {:noreply, update_in(state.messages, &(&1 ++ [{:msg, payload}]))}
  end

  @impl GenServer
  def handle_call(:close, _from, state) do
    {:reply, :ok, update_in(state.messages, &(&1 ++ [:close]))}
  end

  # Stub-only callbacks
  def handle_call({:set_test, pid}, _from, %{test_pid: nil} = state) do
    Process.monitor(pid)
    {:reply, :ok, state |> Map.put(:test_pid, pid) |> Map.put(:messages, [])}
  end

  def handle_call({:set_test, _pid}, _from, state) do
    {:reply, {:error, :already_assigned}, state}
  end

  def handle_call(:has_closed?, _from, state) do
    pop_by(state, &(&1 == :close))
  end

  def handle_call({:has_message?, func}, _from, state) do
    pop_by(state, fn
      {:msg, msg} -> func.(msg)
      _ -> false
    end)
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{test_pid: t_pid} = state)
      when pid == t_pid do
    {:noreply, Map.put(state, :test_pid, nil)}
  end

  defp pop_by(state, func) do
    state.messages
    |> Enum.find_index(func)
    |> case do
      nil -> {:reply, false, state}
      index -> {:reply, true, update_in(state.messages, &List.delete_at(&1, index))}
    end
  end
end
