defmodule Mobius.Core.Rest.ClientTest do
  use ExUnit.Case, async: true

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Core.Rest.Client

  setup :create_token
  setup :create_rest_client

  describe "parse_response/2" do
    test "returns {:error, :unauthorized_token} on status 401", ctx do
      url = Client.base_url() <> "/401"
      mock(fn %{method: :get, url: ^url} -> {401, [], ""} end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :unauthorized_token} == response
    end

    test "returns {:error, :forbidden} on status 403", ctx do
      url = Client.base_url() <> "/403"
      mock(fn %{method: :get, url: ^url} -> {403, [], ""} end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :forbidden} == response
    end

    test "returns {:error, :not_found} on status 404", ctx do
      url = Client.base_url() <> "/404"
      mock(fn %{method: :get, url: ^url} -> {404, [], ""} end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :not_found} == response
    end

    test "returns {:error, :ratelimited} on status 429", ctx do
      url = Client.base_url() <> "/429"
      mock(fn %{method: :get, url: ^url} -> {429, [], ""} end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :ratelimited} == response
    end

    test "returns the error given by the adapter if any", ctx do
      url = Client.base_url() <> "/error"
      mock(fn %{method: :get, url: ^url} -> {:error, :timeout} end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :timeout} == response
    end

    test "returns {:ok, parser.()} on status 201", ctx do
      url = Client.base_url() <> "/201"
      value = random_hex(8)
      mock(fn %{method: :get, url: ^url} -> json(%{"key" => value}, 201) end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:ok, %{key: value}} == response
    end

    test "returns {:ok, parser.()} on status 200", ctx do
      url = Client.base_url() <> "/ok"
      value = random_hex(8)
      mock(fn %{method: :get, url: ^url} -> json(%{"key" => value}) end)

      response =
        Tesla.get(ctx.client, url)
        |> Client.parse_response(&stub_parser/1)

      assert {:ok, %{key: value}} == response
    end
  end

  def stub_parser(%{"key" => value}), do: %{key: value}
  def stub_parser(input), do: input
end
