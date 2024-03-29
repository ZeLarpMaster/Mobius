defmodule Mobius.Services.CogLoader do
  @moduledoc false

  use GenServer

  alias Mobius.Cog

  @initial_cogs [Mobius.Cogs.Help, Mobius.Cogs.PingPong]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec load_cog(module()) :: :ok | {:error, any()}
  def load_cog(cog) do
    GenServer.call(__MODULE__, {:load_cog, cog})
  end

  @spec list_cogs() :: [Cog.t()]
  def list_cogs do
    cogs = GenServer.call(__MODULE__, :list_cogs)

    cogs
    |> Enum.filter(&function_exported?(&1, :__cog__, 0))
    |> Enum.map(& &1.__cog__())
  end

  @impl true
  def init(_init_arg) do
    Enum.each(@initial_cogs, &start_cog/1)

    {:ok, %{cogs: @initial_cogs}}
  end

  @impl true
  def handle_call(:list_cogs, _from, state) do
    {:reply, state.cogs, state}
  end

  @impl true
  def handle_call({:load_cog, cog}, _from, state) do
    case start_cog(cog) do
      {:ok, _pid} -> {:reply, :ok, %{state | cogs: [cog | state.cogs]}}
      :ignore -> {:reply, {:error, :ignore}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  defp start_cog(cog) do
    DynamicSupervisor.start_child(Mobius.Supervisor.CogLoader, cog)
  end
end
