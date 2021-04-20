defmodule Mobius.Services.ModelCache do
  @moduledoc false

  use Supervisor

  alias Mobius.Core.Event

  @type cache :: __MODULE__.User | __MODULE__.Member | __MODULE__.Guild

  @caches [
    __MODULE__.Guild,
    # __MODULE__.Channel,
    # __MODULE__.Permissions,
    # __MODULE__.Role,
    # __MODULE__.Emoji,
    # __MODULE__.Message,
    __MODULE__.User,
    __MODULE__.Member
  ]

  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(_opts) do
    # Start each individual cache
    @caches
    |> Enum.map(&cache_spec/1)
    |> Supervisor.init(strategy: :one_for_one)
  end

  @doc """
  Gets a value from a cache using its key or returns nil if not found

  Models with composite keys (such as members who have a guild id and a user id as a key)
  have tuple as the key with all the keys in the tuple (ie.: {guild_id, user_id} for members).
  """
  @spec get(any, cache()) :: any
  def get(key, cache) do
    {:ok, value} = Cachex.get(cache, key)
    value
  end

  @doc "Lists all the values in a given cache"
  @spec list(cache()) :: Enumerable.t(any)
  def list(cache) do
    {:ok, stream} = Cachex.stream(cache, Cachex.Query.create(true, :value))
    stream
  end

  @doc "Clears all caches"
  @spec clear :: :ok
  def clear do
    Enum.each(@caches, &Cachex.clear!/1)
    :ok
  end

  @doc """
  Extracts cacheable data from an event

  For example, `Guild Member Add` receives a guild member as data which contains a user.
  Both the user and the member are cached.
  """
  @spec cache_event(Event.name(), any) :: any
  def cache_event(:ready, data), do: cache_user(data["user"])
  def cache_event(:user_update, user), do: cache_user(user)
  def cache_event(:guild_member_add, member), do: cache_member(member)
  def cache_event(:guild_member_remove, data), do: invalidate_member(data)
  def cache_event(:guild_update, guild), do: update_cache(__MODULE__.Guild, guild["id"], guild)
  def cache_event(:guild_delete, guild), do: invalidate_guild(guild)

  def cache_event(:guild_create, guild) do
    cache_guild(guild)

    guild
    |> Map.get("members", [])
    |> Enum.map(fn member -> member["user"] end)
    |> cache_users()
  end

  def cache_event(:guild_member_update, member) do
    update_cache(
      __MODULE__.Member,
      {member["guild_id"], member["user"]["id"]},
      Map.delete(member, "guild_id")
    )
  end

  def cache_event(_event, _data), do: nil

  defp cache_guild(guild), do: Cachex.put(__MODULE__.Guild, guild["id"], guild)
  defp invalidate_guild(%{"id" => id}), do: Cachex.del(__MODULE__.Guild, id)

  defp cache_user(user), do: Cachex.put(__MODULE__.User, user["id"], user)

  defp cache_users(users) do
    Cachex.put_many(__MODULE__.User, Enum.map(users, fn user -> {user["id"], user} end))
  end

  defp cache_member(member) do
    user = member["user"]
    cache_user(user)
    key = {member["guild_id"], user["id"]}

    Cachex.put(__MODULE__.Member, key, Map.delete(member, "guild_id"))
  end

  defp invalidate_member(%{"guild_id" => guild_id, "user" => %{"id" => id}}) do
    Cachex.del(__MODULE__.Member, {guild_id, id})
  end

  defp update_cache(cache, key, new_value) do
    Cachex.get_and_update(cache, key, fn
      nil -> {:commit, new_value}
      old_value -> {:commit, Map.merge(old_value, new_value)}
    end)
  end

  defp cache_spec(name), do: Supervisor.child_spec({Cachex, name: name}, id: name)
end
