defmodule Mobius.Validations.EventValidator do
  @moduledoc false

  alias Mobius.Core.Event
  alias Mobius.Core.Intents
  alias Mobius.Validations.Utils

  @doc """
  Validates each name to ensure they exist and are covered by the intents.

  Returns :ok if everything is valid

  Returns {:errors, [String.t()]} with a list of error explanations if any is invalid
  """
  @spec validate_events([any], Intents.t()) :: Utils.output()
  def validate_events(names, intents) do
    names
    |> Utils.check_list(&validate(&1, intents))
    |> Utils.errors_to_output()
  end

  defp validate(name, intents) do
    cond do
      not Event.is_event_name?(name) ->
        {:error, "invalid event name: #{inspect(name)}"}

      not Intents.has_intent_for_event?(name, intents) ->
        {:error, "no intent for #{inspect(name)}"}

      true ->
        :ok
    end
  end
end
