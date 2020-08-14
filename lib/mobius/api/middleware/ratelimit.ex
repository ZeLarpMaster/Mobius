defmodule Mobius.Api.Middleware.Ratelimit do
  @moduledoc false

  alias __MODULE__.Server

  @behaviour Tesla.Middleware

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    # TODO: Figure out what to do with GenServer if the process dies
    Server.start_link(opts)
  end

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(arg) do
    Server.child_spec(arg)
  end

  @impl Tesla.Middleware
  def call(%Tesla.Env{} = env, next, options) do
    server = Keyword.fetch!(options, :server)

    env
    |> enforce_ratelimit(server)
    |> Tesla.run(next)
    |> check_ratelimits(server)
  end

  defp enforce_ratelimit(%Tesla.Env{} = env, server) do
    params = Keyword.get(env.opts, :path_params, [])

    bucket = {
      env.url,
      Keyword.get(params, :guild_id),
      Keyword.get(params, :channel_id),
      Keyword.get(params, :webhook_id)
    }

    Server.wait_ratelimit(server, "global")
    Server.wait_ratelimit(server, bucket)

    %Tesla.Env{env | opts: Keyword.put(env.opts, :ratelimit_bucket, bucket)}
  end

  defp check_ratelimits({:ok, env}, server), do: {:ok, check_ratelimits(env, server)}
  defp check_ratelimits({:error, reason}, _server), do: {:error, reason}

  defp check_ratelimits(%Tesla.Env{status: 429} = env, server) do
    case env.body do
      %{"global" => true, "retry_after" => retry_after} ->
        Server.update_ratelimit(server, "global", "global", 0, retry_after)
        env

      _ ->
        update_route_ratelimit(env, server)
        env
    end
  end

  defp check_ratelimits(%Tesla.Env{} = env, server) do
    update_route_ratelimit(env, server)
    env
  end

  defp update_route_ratelimit(%Tesla.Env{} = env, server) do
    route = Keyword.fetch!(env.opts, :ratelimit_bucket)
    remaining = Tesla.get_header(env, "x-ratelimit-remaining")
    reset_after = Tesla.get_header(env, "x-ratelimit-reset-after")
    bucket = Tesla.get_header(env, "x-ratelimit-bucket")

    update_route_ratelimit(server, route, bucket, remaining, reset_after)
  end

  defp update_route_ratelimit(_, _, nil, _, _), do: nil
  defp update_route_ratelimit(_, _, _, nil, _), do: nil
  defp update_route_ratelimit(_, _, _, _, nil), do: nil

  defp update_route_ratelimit(server, route, bucket, remaining, reset_after) do
    remaining = String.to_integer(remaining)
    reset_after = parse_reset_after(reset_after)
    Server.update_ratelimit(server, route, bucket, remaining, reset_after)
  end

  defp parse_reset_after(reset_after) do
    reset_after
    |> String.replace(".", "")
    |> String.to_integer()
  end
end
