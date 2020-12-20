defmodule Mobius.Validations.EventValidator do
  @moduledoc false

  alias Mobius.Core.Event
  alias Mobius.Validations.Utils

  @spec validate_names([any]) :: Utils.out()
  def validate_names(names) do
    names
    |> Utils.check_list(&validate_name/1)
    |> Utils.errors_to_output()
  end

  defp validate_name(name) do
    if Event.is_event_name?(name) do
      :ok
    else
      {:error, "invalid event name: #{inspect(name)}"}
    end
  end
end
