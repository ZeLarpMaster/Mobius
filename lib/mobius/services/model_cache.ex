defmodule Mobius.Services.ModelCache do
  @moduledoc false

  use Supervisor

  alias Mobius.Core.Event

  @type cache :: __MODULE__.User

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

  @spec get(any, cache()) :: any
  def get(key, cache) do
    {:ok, value} = Cachex.get(cache, key)
    value
  end

  @spec list(cache()) :: [any]
  def list(cache) do
    {:ok, stream} = Cachex.stream(cache, Cachex.Query.create(true, :value))
    Enum.to_list(stream)
  end

  @spec cache_event(Event.name(), any) :: any
  def cache_event(:ready, data), do: cache_user(data["user"])
  def cache_event(:channel_create, _channel), do: nil
  def cache_event(:channel_update, _channel), do: nil
  def cache_event(:channel_delete, _data), do: nil
  def cache_event(:channel_pins_update, _data), do: nil
  def cache_event(:guild_create, _guild), do: nil
  def cache_event(:guild_update, _guild), do: nil
  def cache_event(:guild_delete, _data), do: nil
  def cache_event(:guild_ban_add, _ban), do: nil
  def cache_event(:guild_ban_remove, _ban), do: nil
  def cache_event(:guild_emojis_update, _data), do: nil
  def cache_event(:guild_integrations_update, _data), do: nil
  def cache_event(:guild_member_add, member), do: cache_member(member)
  def cache_event(:guild_member_remove, data), do: invalidate_member(data)

  def cache_event(:guild_member_update, data) do
    Cachex.get_and_update(__MODULE__.Member, {data["guild_id"], data["user"]["id"]}, fn
      nil -> {:ignore, nil}
      member -> {:commit, Map.merge(member, Map.delete(data, "guild_id"))}
    end)
  end

  def cache_event(:guild_role_create, _data), do: nil
  def cache_event(:guild_role_update, _data), do: nil
  def cache_event(:guild_role_delete, _data), do: nil
  def cache_event(:invite_create, _data), do: nil
  def cache_event(:invite_delete, _data), do: nil
  def cache_event(:message_create, _message), do: nil
  def cache_event(:message_update, _message), do: nil
  def cache_event(:message_delete, _data), do: nil
  def cache_event(:message_delete_bulk, _data), do: nil
  def cache_event(:message_reaction_add, _data), do: nil
  def cache_event(:message_reaction_remove, _data), do: nil
  def cache_event(:message_reaction_remove_all, _data), do: nil
  def cache_event(:message_reaction_remove_emoji, _data), do: nil
  def cache_event(:presence_update, _data), do: nil
  def cache_event(:typing_start, _data), do: nil
  def cache_event(:user_update, user), do: cache_user(user)
  def cache_event(:voice_state_update, _data), do: nil
  def cache_event(:voice_server_update, _data), do: nil
  def cache_event(:webhooks_update, _data), do: nil

  defp cache_user(user), do: Cachex.put(__MODULE__.User, user["id"], user)

  defp cache_member(member) do
    user = member["user"]
    cache_user(user)
    Cachex.put(__MODULE__.Member, {member["guild_id"], user["id"]}, member)
  end

  defp invalidate_member(%{"guild_id" => guild_id, "user" => %{"id" => id}}) do
    Cachex.del(__MODULE__.Member, {guild_id, id})
  end

  defp cache_spec(name), do: Supervisor.child_spec({Cachex, name: name}, id: name)
end
