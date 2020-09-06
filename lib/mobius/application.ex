defmodule Mobius.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, list) :: {:ok, pid}
  def start(_type, _args) do
    children = [
      registry(Mobius.Registry.Heartbeat),
      registry(Mobius.Registry.Shard),
      registry(Mobius.Registry.Socket),
      dynamic_supervisor(Mobius.Supervisor.Heartbeat),
      dynamic_supervisor(Mobius.Supervisor.Shard),
      dynamic_supervisor(Mobius.Supervisor.Socket)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mobius.Supervisor)
  end

  defp dynamic_supervisor(name),
    do: {DynamicSupervisor, name: name, strategy: :one_for_one, max_restarts: 1}

  defp registry(name), do: {Registry, name: name, keys: :unique}
end
