defmodule Mobius.Services.PubSub do
  @moduledoc false

  @doc """
  Returns a specification to start a PubSub under a supervisor.

  See `Supervisor` for more details.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(_opts) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  @doc """
  Subscribes the caller to a topic on the pubsub.

  A caller can subscribe to the same topic multiple times,
  but will receive duplicate events

  A list of event names may be passed to only receive events
  such that `Enum.member?(events, event)` is true when publishing
  where `events` is the event names list passed here and `event` is
  the 2nd argument of `publish/3`. An empty list means no filtering
  is done and the caller will receive all events for the topic.
  """
  @spec subscribe(String.t(), list(atom)) :: :ok
  def subscribe(topic, events \\ []) do
    {:ok, _} = Registry.register(__MODULE__, topic, MapSet.new(events))
    :ok
  end

  @doc """
  Unsubscribes the caller from a topic on the pubsub.

  If the caller was subscribed to the topic multiple times,
  they will be unsubscribed completely such that the caller
  no longer receives *any* events from that topic.
  """
  @spec unsubscribe(String.t()) :: :ok
  def unsubscribe(topic) do
    Registry.unregister(__MODULE__, topic)
  end

  @doc """
  Sends an event to all subscribed processes.

  Processes subscribed to the topic with a list of events which
  doesn't include this event's name will not receive the message.
  The dispatching to other processes and filtering is executed by
  the caller of this function.
  If a large number of processes are subscribed, the caller may
  be spending a lot of time dispatching.
  The message sent to all subscribed processes is `{event, value}`.
  Events might need to be namespaced if conflicts with other messages occur.
  """
  @spec publish(String.t(), atom, any) :: :ok
  def publish(topic, event, value) do
    Registry.dispatch(
      __MODULE__,
      topic,
      fn entries ->
        for {pid, events} <- entries, Enum.empty?(events) or Enum.member?(events, event) do
          send(pid, {event, value})
        end
      end,
      parallel: true
    )
  end
end
