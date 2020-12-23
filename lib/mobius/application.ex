defmodule Mobius.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, list) :: {:ok, pid}
  def start(_type, _args) do
    children = [
      {Mobius.Services.ETSShelf, []},
      registry(Mobius.Registry.Heartbeat),
      registry(Mobius.Registry.Shard),
      registry(Mobius.Registry.Socket),
      dynamic_supervisor(Mobius.Supervisor.Heartbeat),
      dynamic_supervisor(Mobius.Supervisor.Shard),
      dynamic_supervisor(Mobius.Supervisor.Socket),
      {Mobius.Services.RestRatelimiter, []},
      {Mobius.Services.PubSub, []},
      {Mobius.Services.EventPipeline, []},
      {Mobius.Services.Bot, token: System.get_env("MOBIUS_BOT_TOKEN")}
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
