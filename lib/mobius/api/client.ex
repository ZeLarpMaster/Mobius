defmodule Mobius.Api.Client do
  @moduledoc false

  require Logger

  alias Mobius.Parsers.Utils

  @type client :: any
  @type errors :: :unauthorized_token | :forbidden | :not_found | :ratelimited | any
  @type error :: {:error, errors() | Utils.error()}

  @api_vsn 6
  @adapter Application.compile_env!(:mobius, :tesla_adapter)

  defguardp is_not_error(value) when not is_tuple(value) or elem(value, 0) != :error

  @spec new(String.t(), GenServer.server()) :: client()
  def new(token, ratelimit_server) do
    headers = [
      {"User-Agent",
       "DiscordBot" <>
         " (Mobius, #{Application.spec(:mobius, :vsn)})" <>
         " Elixir/#{System.version()}" <>
         " Mint/#{Application.spec(:mint, :vsn)}"},
      {"X-RateLimit-Precision", "millisecond"},
      {"Authorization", "Bot #{token}"}
    ]

    middleware = [
      {Tesla.Middleware.Retry, should_retry: &client_should_retry?/1},
      {Mobius.Api.Middleware.Ratelimit, server: ratelimit_server},
      {Tesla.Middleware.BaseUrl, base_url()},
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middleware, @adapter)
  end

  @spec base_url :: String.t()
  def base_url, do: "https://discord.com/api/v#{@api_vsn}"

  @spec check_empty_response(Tesla.Env.result()) :: :ok | error()
  def check_empty_response(response) do
    with {:ok, response} <- response do
      check_status(response)
    end
  end

  @spec parse_response(Tesla.Env.result(), module, atom) :: {:ok, any} | error()
  def parse_response(response, module, parser) do
    with {:ok, response} <- response,
         {:ok, body} <- check_status(response),
         result when is_not_error(result) <- apply(module, parser, [body]) do
      {:ok, result}
    end
  end

  defp check_status(%Tesla.Env{status: 400, body: body}), do: {:error, :bad_request, body}
  defp check_status(%Tesla.Env{status: 401}), do: {:error, :unauthorized_token}
  defp check_status(%Tesla.Env{status: 403}), do: {:error, :forbidden}
  defp check_status(%Tesla.Env{status: 404}), do: {:error, :not_found}
  defp check_status(%Tesla.Env{status: 429}), do: {:error, :ratelimited}
  defp check_status(%Tesla.Env{status: 204, body: body}) when body in [nil, ""], do: :ok
  defp check_status(%Tesla.Env{status: 201, body: body}), do: {:ok, body}
  defp check_status(%Tesla.Env{status: 200, body: body}), do: {:ok, body}
  defp check_status(%Tesla.Env{} = env), do: {:error, env.status, env.body}

  defp client_should_retry?({:error, _}), do: true
  defp client_should_retry?({:ok, %{status: status}}) when status in [429, 500, 502], do: true
  defp client_should_retry?({:ok, _}), do: false
end
