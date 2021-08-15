defmodule Mobius.Endpoint do
  @moduledoc """
  An endpoint that can be used to interact with Discord

  The attributes of an endpoint are the following:
  - name: The name of the endpoint. This will correspond to the name of the
  exposed by Mobius to query this endpoint.
  - url: The url at which Discord exposes the endpoint.
  - method: The HTTP method to use when sending requests to Discord.
  - params: The list of query parameters the endpoint accepts.
  - opts: The options that the endpoint accepts. These generally correspond to
  the HTTP request's body.
  - model: The Mobius model HTTP responses should be parsed into. No model means
  that the request is not expected to return any data.
  - list_response?: Whether or not the request returns a list of entities.
  """

  alias Mobius.Validations.ActionValidations

  @enforce_keys ~w(name url method params)a
  defstruct [:name, :url, :method, :params, :opts, :model, :list_response?]

  @type t :: %__MODULE__{
          name: atom(),
          url: String.t(),
          method: :get | :post | :patch | :delete,
          params: [atom()],
          opts: %{atom() => ActionValidations.validator_type()} | nil,
          model: atom() | nil,
          list_response?: boolean() | nil
        }

  @spec get_arguments_names(t()) :: [atom()]
  def get_arguments_names(%__MODULE__{opts: nil} = endpoint), do: endpoint.params
  def get_arguments_names(%__MODULE__{} = endpoint), do: endpoint.params ++ [:params]
end
