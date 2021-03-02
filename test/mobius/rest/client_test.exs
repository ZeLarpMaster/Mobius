defmodule Mobius.Rest.ClientTest do
  use ExUnit.Case

  import Tesla.Mock, only: [mock: 1]
  import Mobius.Fixtures

  alias Mobius.Rest.Client

  setup :create_rest_client

  describe "parse_response/2" do
    test "translates {:error, :unavailable} to {:error, :unauthorized_token}", ctx do
      url = Client.base_url() <> "/401"
      mock(fn %{method: :get, url: ^url} -> {401, [], ""} end)

      # Requesting after receiving a 401 will return `{:error, :unavailable}`
      Client.check_empty_response(Tesla.get(ctx.client, url))
      response = Client.check_empty_response(Tesla.get(ctx.client, url))

      assert {:error, :unauthorized_token} == response
    end

    test "returns {:error, :unauthorized_token} on status 401", ctx do
      url = Client.base_url() <> "/401"
      mock(fn %{method: :get, url: ^url} -> {401, [], ""} end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :unauthorized_token} == response
    end

    test "returns {:error, :forbidden} on status 403", ctx do
      url = Client.base_url() <> "/403"
      mock(fn %{method: :get, url: ^url} -> {403, [], ""} end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :forbidden} == response
    end

    test "returns {:error, :not_found} on status 404", ctx do
      url = Client.base_url() <> "/404"
      mock(fn %{method: :get, url: ^url} -> {404, [], ""} end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :not_found} == response
    end

    test "returns {:error, :ratelimited} on status 429", ctx do
      url = Client.base_url() <> "/429"
      mock(fn %{method: :get, url: ^url} -> {429, [], ""} end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :ratelimited} == response
    end

    test "returns the error given by the adapter if any", ctx do
      url = Client.base_url() <> "/error"
      mock(fn %{method: :get, url: ^url} -> {:error, :timeout} end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:error, :timeout} == response
    end

    test "returns {:ok, parser.()} on status 201", ctx do
      url = Client.base_url() <> "/201"
      value = random_hex(8)
      mock(fn %{method: :get, url: ^url} -> json(%{"key" => value}, 201) end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:ok, %{key: value}} == response
    end

    test "returns {:ok, parser.()} on status 200", ctx do
      url = Client.base_url() <> "/ok"
      value = random_hex(8)
      mock(fn %{method: :get, url: ^url} -> json(%{"key" => value}) end)

      response =
        ctx.client
        |> Tesla.get(url)
        |> Client.parse_response(&stub_parser/1)

      assert {:ok, %{key: value}} == response
    end
  end

  describe "invalid token handling" do
    setup do
      test_pid = self()
      url = Client.base_url() <> "/401"

      mock(fn %{method: :get, url: ^url} ->
        send(test_pid, :called_api)
        {401, [], ""}
      end)

      [url: url]
    end

    test "prevents calls after receiving a 401", ctx do
      Tesla.get(ctx.client, ctx.url)
      assert_received :called_api

      Tesla.get(ctx.client, ctx.url)
      refute_received :called_api
    end

    test "allows new calls when a new client is made", ctx do
      Tesla.get(ctx.client, ctx.url)
      assert_received :called_api

      ctx
      |> create_rest_client()
      |> Keyword.fetch!(:client)
      |> Tesla.get(ctx.url)

      assert_received :called_api
    end
  end

  def stub_parser(%{"key" => value}), do: %{key: value}
  def stub_parser(input), do: input
end
