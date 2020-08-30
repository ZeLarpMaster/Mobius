defmodule Mobius.Services.Shard do
  @moduledoc false

  use GenServer

  alias Mobius.Core.ShardInfo

  @typep state :: %{
           seq: integer,
           session_id: String.t() | nil,
           token: String.t(),
           info: ShardInfo.t()
         }

  @impl GenServer
  @spec init(keyword) :: {:ok, state()}
  def init(opts) do
    %ShardInfo{} = shard_info = Keyword.fetch!(opts, :shard_info)

    state = %{
      seq: 0,
      session_id: nil,
      token: Keyword.fetch!(opts, :token),
      info: shard_info
    }

    {:ok, state}
  end
end
