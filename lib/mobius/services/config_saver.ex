defmodule Mobius.Services.ConfigSaver do
  @moduledoc false

  use GenServer

  alias Mobius.Config

  @type state :: %{
          save_interval_ms: non_neg_integer(),
          save_later_ref: reference() | nil,
          configs_to_save: list(atom)
        }

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Notifies that a change occured in a config

  If a change was already notified since the previous save, this does nothing

  Otherwise the server will keep track that this config changed
  and will `Mobius.Config.save/1` it later on
  """
  @spec notify_config_change(atom) :: :ok
  def notify_config_change(config_name) do
    GenServer.call(__MODULE__, {:notify_config_change, config_name})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    {:ok,
     %{
       save_interval_ms: Keyword.fetch!(opts, :save_interval_ms),
       save_later_ref: nil,
       configs_to_save: []
     }}
  end

  @impl GenServer
  def handle_call({:notify_config_change, config_name}, _from, state) do
    state
    |> maybe_save_later()
    |> maybe_store_config_name(config_name)
    |> then(fn state -> {:reply, :ok, state} end)
  end

  @impl GenServer
  def handle_info(:save_config, state) do
    # This loop is saving only one config at a time to avoid stressing the storage with autosaves
    %{state | save_later_ref: nil}
    |> maybe_save_config()
    |> maybe_save_later()
    |> then(fn state -> {:noreply, state} end)
  end

  defp maybe_save_config(state) do
    case state.configs_to_save do
      [] ->
        state

      [config | configs] ->
        Config.save(config)
        put_in(state.configs_to_save, configs)
    end
  end

  defp maybe_save_later(%{save_later_ref: nil} = state), do: save_later(state)
  defp maybe_save_later(state), do: state

  defp maybe_store_config_name(state, config_name) do
    # That's indeed not a very efficient way to go about it
    # But it's very simple and we don't expect this list to get in the thousands anyway
    if Enum.member?(state.configs_to_save, config_name) do
      state
    else
      update_in(state.configs_to_save, &(&1 ++ [config_name]))
    end
  end

  defp save_later(state) do
    timer_ref = Process.send_after(__MODULE__, :save_config, state.save_interval_ms)
    put_in(state.save_later_ref, timer_ref)
  end
end
