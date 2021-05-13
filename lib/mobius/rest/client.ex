defmodule Mobius.Rest.Client do
  @moduledoc false

  require Logger

  @type client :: Tesla.Client.t()
  @type errors :: :unauthorized_token | :forbidden | :not_found | :ratelimited | any
  @type error :: {:error, errors()}
  @type result(arg) :: {:ok, arg} | error()
  @type empty_result :: :ok | error()

  @lib_url "https://github.com/ZeLarpMaster/Mobius"
  @api_vsn 8

  defguardp is_not_error(value) when not is_tuple(value) or elem(value, 0) != :error

  @spec new(keyword) :: client()
  def new(opts) do
    token = Keyword.fetch!(opts, :token)
    retries = Keyword.get(opts, :max_retries, 5)

    headers = [
      {"User-Agent",
       "DiscordBot" <>
         " (#{@lib_url}, #{Application.spec(:mobius, :vsn)})" <>
         " Elixir/#{System.version()}"},
      {"Authorization", "Bot #{token}"}
    ]

    fuse_opts = [
      # Reset after one day, allowing one call per day if the token keeps being invalid
      opts: {{:standard, 1, 60_000}, {:reset, 24 * 60 * 60 * 1000}},
      name: __MODULE__,
      keep_original_error: true,
      should_melt: &client_should_melt?/1
    ]

    :fuse.reset(__MODULE__)

    middleware = [
      {Tesla.Middleware.Fuse, fuse_opts},
      {Tesla.Middleware.Retry, max_retries: retries, should_retry: &client_should_retry?/1},
      Mobius.Rest.Middleware.Ratelimit,
      {Tesla.Middleware.BaseUrl, base_url()},
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    adapter = Application.get_env(:mobius, :tesla_adapter, Tesla.Adapter.Hackney)

    Tesla.client(middleware, adapter)
  end

  @spec base_url() :: String.t()
  def base_url, do: "https://discord.com/api/v#{@api_vsn}"

  @spec check_empty_response(Tesla.Env.result()) :: empty_result()
  def check_empty_response(response) do
    case response do
      {:ok, response} -> check_status(response)
      # Error when Tesla.Middleware.Fuse melts
      {:error, :unavailable} -> {:error, :unauthorized_token}
      error -> error
    end
  end

  @spec parse_response(Tesla.Env.result(), (any -> arg)) :: {:ok, arg} | error() when arg: var
  def parse_response(response, parser_func) do
    with {:ok, response} <- response,
         {:ok, body} <- check_status(response),
         result when is_not_error(result) <- parser_func.(body) do
      {:ok, result}
    else
      # Error when Tesla.Middleware.Fuse melts
      {:error, :unavailable} -> {:error, :unauthorized_token}
      error -> error
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

  defp client_should_retry?({:error, :forbidden}), do: false
  defp client_should_retry?({:error, :unauthorized_token}), do: false
  defp client_should_retry?({:error, _}), do: true
  defp client_should_retry?({:error, error, _}), do: error in [:bad_request]
  defp client_should_retry?({:ok, %{status: status}}) when status in [429, 500, 502], do: true
  defp client_should_retry?({:ok, _}), do: false

  defp client_should_melt?({:ok, %Tesla.Env{status: 401}}) do
    # Melt a 2nd time cause we can't config it to 0 tolerance :(
    # See: https://github.com/jlouis/fuse/pull/27
    :fuse.melt(__MODULE__)
    true
  end

  defp client_should_melt?(_), do: false
end
