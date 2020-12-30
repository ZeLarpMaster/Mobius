defmodule Mobius.Rest.Middleware.Ratelimit do
  @moduledoc false

  alias Mobius.Services.RestRatelimiter

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(%Tesla.Env{} = env, next, _options) do
    env
    |> enforce_ratelimit()
    |> Tesla.run(next)
    |> update_ratelimits()
  end

  defp enforce_ratelimit(%Tesla.Env{} = env) do
    params = Keyword.get(env.opts, :path_params, [])

    bucket = {
      env.url,
      Keyword.get(params, :guild_id),
      Keyword.get(params, :channel_id),
      Keyword.get(params, :webhook_id)
    }

    RestRatelimiter.wait_ratelimit("global")
    RestRatelimiter.wait_ratelimit(bucket)

    # Tag the request's bucket so we know which one to update when we get the response
    %Tesla.Env{env | opts: Keyword.put(env.opts, :ratelimit_bucket, bucket)}
  end

  defp update_ratelimits({:error, reason}), do: {:error, reason}

  defp update_ratelimits({:ok, %Tesla.Env{status: 429} = env}) do
    case env.body do
      %{"global" => true, "retry_after" => retry_after} ->
        RestRatelimiter.update_global_ratelimit(retry_after)
        {:ok, env}

      _ ->
        update_route_ratelimit(env)
        {:ok, env}
    end
  end

  defp update_ratelimits({:ok, %Tesla.Env{} = env}) do
    update_route_ratelimit(env)
    {:ok, env}
  end

  defp update_route_ratelimit(%Tesla.Env{} = env) do
    route = Keyword.fetch!(env.opts, :ratelimit_bucket)
    remaining = Tesla.get_header(env, "x-ratelimit-remaining")
    reset_after = Tesla.get_header(env, "x-ratelimit-reset-after")
    bucket = Tesla.get_header(env, "x-ratelimit-bucket")

    update_route_ratelimit(route, bucket, remaining, reset_after)
  end

  defp update_route_ratelimit(_, nil, _, _), do: nil
  defp update_route_ratelimit(_, _, nil, _), do: nil
  defp update_route_ratelimit(_, _, _, nil), do: nil

  defp update_route_ratelimit(route, bucket, remaining, reset_after) do
    remaining = String.to_integer(remaining)
    reset_after = parse_reset_after(reset_after)
    RestRatelimiter.update_route_ratelimit(route, bucket, remaining, reset_after)
  end

  defp parse_reset_after(reset_after) do
    reset_after
    |> String.replace(".", "")
    |> String.to_integer()
  end
end
