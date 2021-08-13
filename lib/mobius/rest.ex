defmodule Mobius.Rest do
  @moduledoc false

  alias Mobius.Endpoint
  alias Mobius.Rest.Client

  @spec execute(Endpoint.t(), Tesla.Client.t(), keyword()) :: Client.result(any())
  def execute(%Endpoint{} = endpoint, client, args) do
    {query_params, args} = Keyword.pop(args, :params)
    {body, args} = Keyword.pop(args, :body)

    base_tesla_options = [opts: [path_params: args]]

    tesla_options =
      if query_params == nil do
        base_tesla_options
      else
        Keyword.put(base_tesla_options, :query, query_params)
      end

    tesla_response =
      if endpoint.method == :post do
        Tesla.post(client, endpoint.url, body, tesla_options)
      else
        Tesla.get(client, endpoint.url, tesla_options)
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
end
