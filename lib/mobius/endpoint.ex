defmodule Mobius.Endpoint do
  @moduledoc """
  An endpoint that can be used to interact with Discord

  The attributes of an endpoint are the following:
  - name: The name of the endpoint. This will correspond to the name of the
  exposed by Mobius to query this endpoint.
  - url: The url at which Discord exposes the endpoint.
  - method: The HTTP method to use when sending requests to Discord.
  - params: The list of query parameters the endpoint accepts.
  - opts: The options that the endpoint accepts. These correspond to
  the HTTP request's body for POST and PATCH requests or to optional query
  parameters for GET requests.
  - model: The Mobius model HTTP responses should be parsed into. No model means
  that the request is not expected to return any data.
  - list_response?: Whether or not the request returns a list of entities.
  - discord_doc_url: The URL for the official Discord documentation for this
  endpoint.
  - doc: The documentation of the function.
  """

  alias Mobius.Validations.ActionValidations

  @enforce_keys ~w(name url method params discord_doc_url doc)a
  defstruct [
    :name,
    :url,
    :method,
    :params,
    :opts,
    :model,
    :discord_doc_url,
    :doc,
    list_response?: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          url: String.t(),
          method: :get | :post | :patch | :delete,
          params: [{atom(), ActionValidations.validator_type()}],
          opts: %{atom() => ActionValidations.validator_type()} | nil,
          model: atom() | nil,
          discord_doc_url: String.t(),
          doc: String.t(),
          list_response?: boolean()
        }

  @spec get_arguments_names(t()) :: [atom()]
  def get_arguments_names(%__MODULE__{} = endpoint) do
    params_names = Enum.map(endpoint.params, fn {name, _type} -> name end)

    if endpoint.opts == nil do
      params_names
    else
      params_names ++ [:params]
    end
  end
end
