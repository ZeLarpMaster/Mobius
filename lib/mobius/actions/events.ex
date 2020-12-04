defmodule Mobius.Actions.Events do
  @moduledoc """
  Functions related to events
  """

  alias Mobius.Services.EventPipeline

  @spec subscribe([atom]) :: :ok
  def subscribe(events) do
    # TODO: Validate event names
    # TODO: Validate intents
    EventPipeline.subscribe_event_categories(events)
  end

  @spec unsubscribe() :: :ok
  def unsubscribe do
    EventPipeline.unsubscribe()
  end
end
