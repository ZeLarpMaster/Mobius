defmodule Mobius.Services.PubSubTest do
  use ExUnit.Case

  alias Mobius.Services.PubSub

  test "receives all events if subscribed without event names" do
    PubSub.subscribe("foo")

    assert_publish("foo", :one, 1)
    assert_publish("foo", :two, 2)
  end

  test "receives only allowed events" do
    PubSub.subscribe("foo", [:bar, :baz])

    refute_publish("foo", :one, 1)
    refute_publish("foo", :two, 2)

    assert_publish("foo", :bar, %{id: 123})
    assert_publish("foo", :baz, nil)
  end

  test "unregisters from events from that topic" do
    PubSub.subscribe("foo")
    PubSub.subscribe("bar")

    assert_publish("foo", :one, 1)
    assert_publish("bar", :one, 1)

    PubSub.unsubscribe("foo")

    refute_publish("foo", :one, 1)
    assert_publish("bar", :one, 1)
  end

  test "unregisters from events even if subscribed multiple times" do
    PubSub.subscribe("foo")
    PubSub.subscribe("foo")

    assert_publish("foo", :one, 1)
    assert_receive {:one, 1}

    PubSub.unsubscribe("foo")

    refute_publish("foo", :one, 1)
  end

  test "receives duplicate events if subscribed multiple times" do
    PubSub.subscribe("foo")
    PubSub.subscribe("foo")

    assert_publish("foo", :one, 1)
    assert_receive {:one, 1}
  end

  test "receives events if subscribed multiple times with different filters" do
    PubSub.subscribe("foo", [:bar])
    PubSub.subscribe("foo", [:baz])

    assert_publish("foo", :bar, "hello")
    refute_receive {:bar, "hello"}
  end

  defp assert_publish(topic, name, value) do
    PubSub.publish(topic, name, value)
    assert_receive {^name, ^value}
  end

  defp refute_publish(topic, name, value) do
    PubSub.publish(topic, name, value)
    refute_receive {^name, ^value}
  end
end
