defmodule Mobius.Rest do
  @moduledoc false

  alias Mobius.Endpoint
  alias Mobius.Model
  alias Mobius.Rest.Client
  alias Tesla.Multipart

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
          Enum.map(entities, &Model.parse(endpoint.model, &1))
        end)

      true ->
        Client.parse_response(tesla_response, &Model.parse(endpoint.model, &1))
    end
  end

  @spec get_query_params_and_body(Endpoint.t(), keyword()) :: {keyword(), keyword(), map()}
  defp get_query_params_and_body(%Endpoint{method: :get}, args) do
    {query_params, args} = Keyword.pop(args, :params, [])
    {args, query_params, %{}}
  end

  defp get_query_params_and_body(%Endpoint{multipart?: true}, args) do
    {body, args} = Keyword.pop(args, :params, %{})

    if Map.has_key?(body, :file) do
      body = Map.drop(body, [:file])
      %{file: {file, filename}} = body

      multipart =
        Multipart.new()
        |> Multipart.add_field("payload_json", Jason.encode!(body),
          headers: [{"content-type", "application/json"}]
        )
        |> Multipart.add_file_content(file, filename,
          name: "file",
          detect_content_type: true
        )

      {args, [], multipart}
    else
      {args, [], Map.new(body)}
    end
  end

  defp get_query_params_and_body(%Endpoint{}, args) do
    {body, args} = Keyword.pop(args, :params, %{})
    {args, [], Map.new(body)}
  end
end
