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
      # {Cachex, name: __MODULE__.Member},
      {Cachex, name: __MODULE__.User}
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
  def cache_event(:channel_create, channel), do: cache_users(channel["recipients"])
  def cache_event(:channel_update, channel), do: cache_users(channel["recipients"])
  def cache_event(:channel_delete, _data), do: nil
  def cache_event(:channel_pins_update, _data), do: nil
  def cache_event(:guild_create, guild), do: cache_users(members_to_users(guild["members"]))
  def cache_event(:guild_update, guild), do: cache_users(members_to_users(guild["members"]))
  def cache_event(:guild_delete, _data), do: nil
  def cache_event(:guild_ban_add, ban), do: cache_user(ban["user"])
  def cache_event(:guild_ban_remove, ban), do: cache_user(ban["user"])
  def cache_event(:guild_emojis_update, data), do: cache_users(members_to_users(data["emojis"]))
  def cache_event(:guild_integrations_update, _data), do: nil
  def cache_event(:guild_member_add, member), do: cache_user(member["user"])
  def cache_event(:guild_member_remove, member), do: cache_user(member["user"])
  def cache_event(:guild_member_update, member), do: cache_user(member["user"])
  def cache_event(:guild_role_create, _data), do: nil
  def cache_event(:guild_role_update, _data), do: nil
  def cache_event(:guild_role_delete, _data), do: nil
  def cache_event(:invite_create, data), do: cache_users([data["inviter"], data["target_user"]])
  def cache_event(:invite_delete, _data), do: nil
  def cache_event(:message_create, message), do: cache_user(message["author"])
  def cache_event(:message_update, message), do: cache_user(message["author"])
  def cache_event(:message_delete, _data), do: nil
  def cache_event(:message_delete_bulk, _data), do: nil
  def cache_event(:message_reaction_add, data), do: cache_user(data["member"]["user"])
  def cache_event(:message_reaction_remove, _data), do: nil
  def cache_event(:message_reaction_remove_all, _data), do: nil
  def cache_event(:message_reaction_remove_emoji, _data), do: nil
  def cache_event(:presence_update, data), do: cache_user(data["user"])
  def cache_event(:typing_start, data), do: cache_user(data["member"]["user"])
  def cache_event(:user_update, user), do: cache_user(user)
  def cache_event(:voice_state_update, data), do: cache_user(data["member"]["user"])
  def cache_event(:voice_server_update, _data), do: nil
  def cache_event(:webhooks_update, _data), do: nil

  defp cache_user(user), do: Cachex.put(__MODULE__.User, user["id"], user)

  defp cache_users(users) do
    users = Enum.map(users || [], fn user -> {user["id"], user} end)
    Cachex.put_many(__MODULE__.User, users)
  end

  defp members_to_users(members), do: Enum.map(members || [], fn member -> member["user"] end)
end
