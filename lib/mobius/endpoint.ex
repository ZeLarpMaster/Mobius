defmodule Mobius.Endpoint do
  @moduledoc """
  An endpoint that can be used to interact with Discord

  The attributes of an endpoint are the following:
  - name: The name of the endpoint. This will correspond to the name of the
  exposed by Mobius to query this endpoint.
  - url: The url at which Discord exposes the endpoint.
  - method: The HTTP method to use when sending requests to Discord.
  - params: The list of query parameters the endpoint accepts.
  - opts: The options that the endpoint accpets. These generaly correspond to
  the HTTP request's body.
  """

  @enforce_keys ~w(name url method params)a
  defstruct [:name, :url, :method, :params, :opts]

  @type t :: %__MODULE__{
          name: atom(),
          url: String.t(),
          method: :get | :post,
          params: [atom()],
          opts: map()
        }
end
