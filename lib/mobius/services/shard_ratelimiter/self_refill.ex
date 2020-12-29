defmodule Mobius.Services.ShardRatelimiter.SelfRefill do
  @moduledoc false

  use GenServer

  alias Mobius.Core.ShardBuckets
  alias Mobius.Services.ShardRatelimiter

  @behaviour ShardRatelimiter

  @impl ShardRatelimiter
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl ShardRatelimiter
  @spec request_access(ShardRatelimiter.bucket()) :: :ok | :ratelimited
  def request_access({bucket, delay, max_tokens}) do
    GenServer.call(__MODULE__, {:acquire, bucket, delay, max_tokens})
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, ShardBuckets.t()}
  def init(_opts) do
    {:ok, ShardBuckets.new()}
  end

  @impl GenServer
  def handle_call({:acquire, bucket_name, delay, max_tokens}, _from, state) do
    {reply, state} = ShardBuckets.acquire(state, bucket_name, max_tokens)
    release_token_later(reply, bucket_name, delay)

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_info({:release, bucket_name}, state) do
    {:noreply, ShardBuckets.release(state, bucket_name)}
  end

  defp release_token_later(:ratelimited, _name, _delay), do: nil

  defp release_token_later(:ok, bucket_name, delay) do
    Process.send_after(self(), {:release, bucket_name}, delay)
  end
end
