defmodule Mobius.Services.CogLoader do
  @moduledoc false

  use GenServer

  @initial_cogs [Mobius.Cogs.PingPong]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec load_cog(module()) :: DynamicSupervisor.on_start_child()
  def load_cog(cog) do
    GenServer.call(__MODULE__, {:load_cog, cog})
  end

  @impl true
  def init(_init_arg) do
    Enum.each(@initial_cogs, &start_cog/1)

    {:ok, @initial_cogs}
  end

  @impl true
  def handle_call({:load_cog, cog}, _from, state) do
    start_cog(cog)
    {:reply, :ok, [cog | state]}
  end

  defp start_cog(cog) do
    DynamicSupervisor.start_child(Mobius.Supervisor.CogLoader, cog)
  end
end
