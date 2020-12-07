defmodule Mobius.Services.EventPipeline do
  @moduledoc false

  alias Mobius.Core.Event
  alias Mobius.Services.PubSub

  @pubsub_topic "events"

  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(_opts) do
    Task.Supervisor.child_spec(name: __MODULE__)
  end

  @doc "Sends an event to all subscribed processes"
  @spec notify_event(String.t(), any) :: :ok
  def notify_event(name, data) do
    # Starting in an unlinked task for 3 reasons:
    # 1. We don't want the source of the events to spend time mapping events
    # 2. We want this work to be parallelized
    # 3. We don't want errors in here to crash the source of events
    Task.Supervisor.start_child(__MODULE__, fn ->
      parsed_name = Event.parse_name(name)

      if parsed_name != nil do
        parsed_data = Event.parse_data(parsed_name, data)
        PubSub.publish(@pubsub_topic, parsed_name, parsed_data)
      end
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
