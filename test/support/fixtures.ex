defmodule Mobius.Fixtures do
  @moduledoc false

  alias Mobius.Core.Rest.Client

  def create_token(_context) do
    [token: random_hex(8)]
  end

  def create_rest_client(context) do
    [client: Client.new(token: context.token)]
  end

  @chars "0123456789abcdef" |> String.codepoints()
  def random_hex(len) do
    1..len
    |> Enum.map(fn _ -> Enum.random(@chars) end)
    |> Enum.join()
  end

  def json(term, status_code \\ 200) do
    {status_code, [{"content-type", "application/json"}], Jason.encode!(term)}
  end
end
