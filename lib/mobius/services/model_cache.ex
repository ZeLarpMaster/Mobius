defmodule Mobius.Services.ModelCache do
  @moduledoc false

  use Supervisor

  alias Mobius.Core.Event

  @type cache :: __MODULE__.User | __MODULE__.Member

  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      # Start each individual cache
      # {Cachex, name: __MODULE__.Guild},
      cache_spec(__MODULE__.Member),
      cache_spec(__MODULE__.User)
      # {Cachex, name: __MODULE__.Channel},
      # {Cachex, name: __MODULE__.Permissions},
      # {Cachex, name: __MODULE__.Role},
      # {Cachex, name: __MODULE__.Emoji},
      # {Cachex, name: __MODULE__.Message}
    ]

    Supervisor.init(children, strategy: :one_for_one)
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
  @spec list(cache()) :: [any]
  def list(cache) do
    {:ok, stream} = Cachex.stream(cache, Cachex.Query.create(true, :value))
    Enum.to_list(stream)
  end

  @doc "Clears all caches. Only for usage in tests."
  @spec clear :: :ok
  def clear do
    Cachex.clear!(__MODULE__.User)
    Cachex.clear!(__MODULE__.Member)
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

  def cache_event(:guild_create, guild) do
    guild
    |> Map.get("members", [])
    |> Enum.map(fn member -> member["user"] end)
    |> cache_users()
  end

  def cache_event(:guild_member_update, %{"guild_id" => guild_id, "user" => %{"id" => id}} = data) do
    new_member = Map.delete(data, "guild_id")

    Cachex.get_and_update(__MODULE__.Member, {guild_id, id}, fn
      nil -> {:commit, new_member}
      member -> {:commit, Map.merge(member, new_member)}
    end)
  end

  def cache_event(_event, _data), do: nil

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

  defp cache_spec(name), do: Supervisor.child_spec({Cachex, name: name}, id: name)
end
