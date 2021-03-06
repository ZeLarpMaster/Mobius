defmodule Mobius.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Mobius.Core.Intents

  @spec start(any, list) :: {:ok, pid}
  def start(_type, _args) do
    children = [
      {Mobius.Services.ModelCache, []},
      {Mobius.Services.ETSShelf, []},
      registry(Mobius.Registry.Heartbeat),
      registry(Mobius.Registry.Shard),
      registry(Mobius.Registry.Socket),
      dynamic_supervisor(Mobius.Supervisor.Heartbeat),
      dynamic_supervisor(Mobius.Supervisor.Shard),
      dynamic_supervisor(Mobius.Supervisor.Socket),
      dynamic_supervisor(Mobius.Supervisor.CogLoader),
      {Mobius.Services.RestRatelimiter, []},
      {Mobius.Services.PubSub, []},
      {Mobius.Services.EventPipeline, []},
      {Mobius.Services.CommandsRatelimiter, []},
      {Mobius.Services.ConnectionRatelimiter, connection_delay_ms: 5_000, ack_timeout_ms: 10_000},
      {Mobius.Services.Bot,
       token: System.get_env("MOBIUS_BOT_TOKEN"), intents: Intents.all_intents()},
      {Mobius.Services.CogLoader, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mobius.Supervisor)
  end

  def reset_services do
    :ok = Application.stop(:mobius)
    :ok = Application.start(:mobius)
  end

  defp dynamic_supervisor(name),
    do: {DynamicSupervisor, name: name, strategy: :one_for_one, max_restarts: 1}

  defp registry(name), do: {Registry, name: name, keys: :unique}
end
