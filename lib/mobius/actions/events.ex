defmodule Mobius.Actions.Events do
  @moduledoc """
  Functions related to events
  """

  alias Mobius.Services.EventPipeline
  alias Mobius.Validations.EventValidator
  alias Mobius.Validations.Utils

  @doc """
  Subscribes the calling process to a set of (or all) events

  Passing invalid event names will cause this function to return `{:errors, [String.t()]}`

  Subscribing multiple times with overlapping events will result
  in duplicate events. As such, it is discouraged to subscribe
  multiple times from the same process since this may cause
  performance degradation

  If an empty list (the default) is given, subscribes to all events

  The caller process is then sent events whose name is in the set
  as messages in the format `{event_name, event_data}`
  where `event_name` is the name of the event as an UPPER_CASE atom
  such as `:CHANNEL_CREATE` and `event_data` is a struct
  containing all the information given by the event

  If the set is not empty,
  the event will be sent if `Enum.member?(events, event_name)` is true

  See https://discord.com/developers/docs/topics/gateway#commands-and-events-gateway-events
  for a list of events and their associated data
  """
  @spec subscribe([any]) :: Utils.output()
  def subscribe(events \\ []) do
    with :ok <- EventValidator.validate_names(events) do
      # TODO: Validate intents
      EventPipeline.subscribe(events)
    end
  end

  @doc """
  Unsubscribes the calling process from all events it was subscribed to

  If the calling process had called `subscribe/1` multiple times,
  this unsubscribes from all of them
  """
  @spec unsubscribe() :: :ok
  def unsubscribe do
    EventPipeline.unsubscribe()
  end
end
