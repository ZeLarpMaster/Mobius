defmodule Mobius.Application do
  @moduledoc false

  use Application

  require Logger

  @supervisor Mobius
  @ratelimit_supervisor Mobius.RateLimitSupervisor

  @spec start(any, list()) :: {:ok, pid}
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: @ratelimit_supervisor},
      {Mobius.PubSub, name: Mobius.Supervisor.pubsub_name()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: @supervisor)
  end

  @spec start_ratelimit_server :: {:ok, pid}
  def start_ratelimit_server do
    {:ok, _pid} =
      DynamicSupervisor.start_child(@ratelimit_supervisor, Mobius.Api.Middleware.Ratelimit)
  end

  @spec stop_ratelimit_server(pid) :: :ok
  def stop_ratelimit_server(pid) when is_pid(pid) do
    :ok = DynamicSupervisor.terminate_child(@ratelimit_supervisor, pid)
  end

  @spec start_bot(keyword) :: {:ok, Mobius.Bot.t()} | {:error, any}
  def start_bot(opts) do
    shard_range = Keyword.fetch!(opts, :shard_range)
    id = Keyword.fetch!(opts, :id)

    if not is_non_neg_range?(shard_range) do
      raise ArgumentError, message: "Shard range cannot include negative numbers"
    end

    if atom_length(id) > 100 do
      raise ArgumentError, message: "The id cannot be longer than 100 codepoints"
    end

    bot = %Mobius.Bot{
      shard_range: shard_range,
      id: Atom.to_string(id),
      registry: :"Bot.#{id}.Registry"
    }

    spec =
      Supervisor.child_spec(
        {Mobius.Supervisor,
         bot: bot,
         intents: Keyword.fetch!(opts, :intents),
         url: Keyword.fetch!(opts, :url),
         token: Keyword.fetch!(opts, :token),
         name: :"Bot.#{id}.Supervisor"},
        id: id
      )

    case Supervisor.start_child(@supervisor, spec) do
      {:ok, _pid} -> {:ok, bot}
      {:error, error} -> error
    end
  end

  @spec stop_bot(atom) :: :ok | {:error, :not_found}
  def stop_bot(bot_id) do
    Logger.debug("Stopping bot: #{bot_id}")

    with :ok = Supervisor.terminate_child(@supervisor, bot_id) do
      Supervisor.delete_child(@supervisor, bot_id)
    end
  end

  defp is_non_neg_range?(min..max), do: min >= 0 and max >= 0

  defp atom_length(atom) do
    atom
    |> Atom.to_string()
    |> String.codepoints()
    |> length()
  end
end
