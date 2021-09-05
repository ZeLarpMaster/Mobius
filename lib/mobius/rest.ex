defmodule Mobius.Rest do
  @moduledoc false

  alias Mobius.Endpoint
  alias Mobius.Rest.Client

  @spec execute(Endpoint.t(), Client.client(), keyword()) :: Client.result(any())
  def execute(%Endpoint{} = endpoint, client, args) do
    {args, query_params, body} = get_query_params_and_body(endpoint, args)

    tesla_options = [opts: [path_params: args], query: query_params]

    tesla_response =
      if endpoint.method in [:post, :patch] do
        apply(Tesla, endpoint.method, [client, endpoint.url, body, tesla_options])
      else
        apply(Tesla, endpoint.method, [client, endpoint.url, tesla_options])
      end

    cond do
      endpoint.model == nil ->
        Client.check_empty_response(tesla_response)

      endpoint.list_response? ->
        Client.parse_response(tesla_response, fn entities ->
          Enum.map(entities, &apply(endpoint.model, :parse, [&1]))
        end)

      true ->
        Client.parse_response(tesla_response, &apply(endpoint.model, :parse, [&1]))
    end
  end

  @spec get_query_params_and_body(Endpoint.t(), keyword()) :: {keyword(), keyword(), map()}
  defp get_query_params_and_body(%Endpoint{method: :get}, args) do
    {query_params, args} = Keyword.pop(args, :params, [])
    {args, query_params, %{}}
  end

  defp get_query_params_and_body(%Endpoint{}, args) do
    {body, args} = Keyword.pop(args, :params, %{})
    {args, [], Map.new(body)}
  end
end
