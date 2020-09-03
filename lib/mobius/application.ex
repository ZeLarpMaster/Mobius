defmodule Mobius.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Mobius.Supervisor.Heartbeat, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mobius.Supervisor)
  end
end
