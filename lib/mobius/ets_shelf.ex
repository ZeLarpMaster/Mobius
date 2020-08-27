defmodule Mobius.ETSShelf do
  @moduledoc false

  use GenServer

  @timeout 1_000

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @spec create_table(GenServer.server(), atom, [atom | tuple]) :: :ok | {:error, :ets_error}
  def create_table(server, name, opts) when is_atom(name) do
    # Creates the table or gives it back if the server already owns it
    with :ok <- GenServer.call(server, {:create, name, self(), opts}) do
      receive do
        {:"ETS-TRANSFER", ^name, _pid, _data} -> :ok
      after
        @timeout -> {:error, :timeout}
      end
    end
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, map}
  def init(_opts) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:create, name, pid, opts}, _from, state) do
    # Set the server as the heir
    opts = opts ++ [{:heir, self(), nil}]

    # This process can't afford to die, so we capture unexpected ets errors
    try do
      {:reply, :ok, create_or_give(name, pid, opts, state)}
    rescue
      ArgumentError -> {:reply, {:error, :ets_error}, state}
    end
  end

  @impl GenServer
  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, state) do
    {:noreply, Map.put(state, table, nil)}
  end

  defp create_or_give(name, pid, opts, state) do
    if not Map.has_key?(state, name) do
      # Attempt to create the table
      # All tables created here are named for simplicity
      :ets.new(name, opts ++ [:named_table])
    end

    :ets.give_away(name, pid, nil)
    Map.put(state, name, pid)
  end
end
