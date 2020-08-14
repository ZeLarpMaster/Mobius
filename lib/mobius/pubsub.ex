defmodule Mobius.PubSub do
  @moduledoc """
  A PubSub service backed by `Registry`

  ## Getting Started

  Start the PubSub in a supervision tree:

      {Mobius.PubSub, name: :pubsub}

  Then use this module's functions to subscribe and publish messages:

      iex> alias Mobius.PubSub
      iex> PubSub.subscribe(:pubsub, "abc")
      :ok
      iex> flush()
      :ok
      iex> PubSub.broadcast(:pubsub, "abc", :user_create, %{id: 123, name: "John Doe"})
      :ok
      iex> flush()
      {:user_create, %{id: 123, name: "John Doe"}}
      :ok
      iex> PubSub.subscribe(:pubsub, "foo", [:bar])
      :ok
      iex> PubSub.broadcast(:pubsub, "foo", :baz, nil)
      :ok
      iex> PubSub.broadcast(:pubsub, "foo", :bar, nil)
      iex> flush()
      {:bar, nil}
      :ok

  # Caveats

  The dispatching of messages is done by the caller of `broadcast/4`
  """

  @doc """
  Returns a specification to start a PubSub under a supervisor.

  See `Supervisor` for more details.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(opts) do
    partitioned? = Keyword.get(opts, :partitioned?, false)
    partitions = if partitioned?, do: System.schedulers_online(), else: 1

    Registry.child_spec(
      keys: :duplicate,
      partitions: partitions,
      name: Keyword.fetch!(opts, :name)
    )
  end

  @doc """
  Subscribes the caller to a topic on the pubsub.

  You can subscribe to the same topic multiple times,
  but you will receive duplicate events

  A list of event names may be passed to only receive events
  such that `Enum.member?(events, event)` is true during broadcast
  where `events` is the event names list passed here
  and `event` is the 3rd argument of `broadcast/4`.
  An empty list means no filtering is done and the caller will
  receive all events for the associated topic.
  """
  @spec subscribe(atom, String.t(), list(atom)) :: :ok
  def subscribe(pubsub, topic, events \\ []) when is_atom(pubsub) do
    {:ok, _} = Registry.register(pubsub, topic, MapSet.new(events))
    :ok
  end

  @doc """
  Unsubscribes the caller from a topic on the pubsub

  If the caller was subscribed to the topic multiple times,
  it will unsubscribe completely such that the caller no longer
  receives *any* events from that topic
  """
  @spec unsubscribe(atom, String.t()) :: :ok
  def unsubscribe(pubsub, topic) when is_atom(pubsub) do
    Registry.unregister(pubsub, topic)
  end

  @doc """
  Sends an event to all subscribed processes

  Processes subscribed to the topic with a list of events which
  doesn't include this event's name will not receive the message.

  The dispatching to other processes and filtering is executed by the caller.
  If a large number of processes are subscribed, the caller may
  be spending a lot of time dispatching.

  The message sent to all subscribed processes is `{event, value}`.
  You may wish to namespace your events if you're having conflicts
  with other messages.
  """
  @spec broadcast(atom, String.t(), atom, any) :: :ok
  def broadcast(pubsub, topic, event, value) when is_atom(pubsub) do
    Registry.dispatch(
      pubsub,
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
