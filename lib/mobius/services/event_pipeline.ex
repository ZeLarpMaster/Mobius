defmodule Mobius.Services.EventPipeline do
  @moduledoc false

  alias Mobius.Services.PubSub

  @pubsub_topic "events"

  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(_opts) do
    Task.Supervisor.child_spec(name: __MODULE__)
  end

  @doc "Sends an event to all subscribed processes"
  @spec notify_event(atom, any) :: :ok
  def notify_event(name, data) do
    Task.Supervisor.start_child(__MODULE__, fn ->
      # TODO: Map data depending on name
      PubSub.publish(@pubsub_topic, name, data)
    end)

    :ok
  end

  @doc "Subscribes the calling process to an arbitrary set of events"
  @spec subscribe_event_categories([atom]) :: :ok
  def subscribe_event_categories(events) do
    PubSub.subscribe(@pubsub_topic, events)
  end

  @doc "Unsubscribes the calling process from all events"
  @spec unsubscribe :: :ok
  def unsubscribe do
    PubSub.unsubscribe(@pubsub_topic)
  end
end
