defmodule Mobius.PubSubTest do
  use ExUnit.Case, async: true

  import Mobius.Fixtures

  alias Mobius.PubSub

  setup :create_pubsub

  test "receives all events if subscribed without event names", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo")

    assert_broadcast(pubsub, "foo", :one, 1)
    assert_broadcast(pubsub, "foo", :two, 2)
  end

  test "receives only allowed events", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo", [:bar, :baz])

    refute_broadcast(pubsub, "foo", :one, 1)
    refute_broadcast(pubsub, "foo", :two, 2)

    assert_broadcast(pubsub, "foo", :bar, %{id: 123})
    assert_broadcast(pubsub, "foo", :baz, nil)
  end

  test "unregisters from events from that topic", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo")
    PubSub.subscribe(pubsub, "bar")

    assert_broadcast(pubsub, "foo", :one, 1)
    assert_broadcast(pubsub, "bar", :one, 1)

    PubSub.unsubscribe(pubsub, "foo")

    refute_broadcast(pubsub, "foo", :one, 1)
    assert_broadcast(pubsub, "bar", :one, 1)
  end

  test "unregisters from events even if subscribed multiple times", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo")
    PubSub.subscribe(pubsub, "foo")

    assert_broadcast(pubsub, "foo", :one, 1)
    assert_receive {:one, 1}

    PubSub.unsubscribe(pubsub, "foo")

    refute_broadcast(pubsub, "foo", :one, 1)
  end

  test "receives duplicate events if subscribed multiple times", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo")
    PubSub.subscribe(pubsub, "foo")

    assert_broadcast(pubsub, "foo", :one, 1)
    assert_receive {:one, 1}
  end

  test "receives events if subscribed multiple times with different filters", %{pubsub: pubsub} do
    PubSub.subscribe(pubsub, "foo", [:bar])
    PubSub.subscribe(pubsub, "foo", [:baz])

    assert_broadcast(pubsub, "foo", :bar, "hello")
    refute_receive {:bar, "hello"}
  end

  defp assert_broadcast(pubsub, topic, name, value) do
    PubSub.broadcast(pubsub, topic, name, value)
    assert_receive {^name, ^value}
  end

  defp refute_broadcast(pubsub, topic, name, value) do
    PubSub.broadcast(pubsub, topic, name, value)
    refute_receive {^name, ^value}
  end
end
