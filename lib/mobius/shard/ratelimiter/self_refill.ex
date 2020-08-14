defmodule Mobius.Shard.Ratelimiter.SelfRefill do
  @moduledoc false

  use GenServer

  alias Mobius.Shard.Ratelimiter

  @typep state :: %{
           buckets: %{optional(String.t()) => non_neg_integer()}
         }

  @behaviour Ratelimiter

  @impl Ratelimiter
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl Ratelimiter
  @spec request_access(GenServer.server(), Ratelimiter.bucket()) :: :ok | :ratelimited
  def request_access(server, {bucket, delay, max_tokens}) do
    GenServer.call(server, {:acquire, bucket, delay, max_tokens})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(_opts) do
    state = %{
      buckets: %{}
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:acquire, bucket_name, delay, max_tokens}, _from, state) do
    {reply, buckets} = acquire_token(state.buckets, bucket_name, max_tokens)
    release_token_later(reply, bucket_name, delay)

    {:reply, reply, %{state | buckets: buckets}}
  end

  @impl GenServer
  def handle_info({:release, bucket_name}, state) do
    buckets = release_token(state.buckets, bucket_name)
    {:noreply, %{state | buckets: buckets}}
  end

  defp acquire_token(buckets, bucket_name, max_tokens) do
    Map.get_and_update(buckets, bucket_name, fn
      nil -> {:ok, max_tokens - 1}
      0 -> {:ratelimited, 0}
      tokens -> {:ok, tokens - 1}
    end)
  end

  defp release_token(buckets, bucket_name) do
    Map.update!(buckets, bucket_name, fn tokens -> tokens + 1 end)
  end

  defp release_token_later(:ratelimited, _name, _delay), do: :ok

  defp release_token_later(:ok, bucket_name, delay) do
    Process.send_after(self(), {:release, bucket_name}, delay)
    :ok
  end
end
