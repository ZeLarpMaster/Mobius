defmodule Mobius.Actions do
  @moduledoc """
  Generation of Mobius actions

  This module contains the macros and functions necessary to generate Mobius
  actions form endpoint definitions.

  ## Warning about exported functions

  The functions exported by this module are not meant to be used directly. They
  are used by the `setup_actions/1` macro, which should be considered to be the
  sole entrypoint for this module.
  """

  alias Mobius.Endpoint
  alias Mobius.Services.Bot
  alias Mobius.Validations.ActionValidations

  @doc """
  Generates actions functions from a list of `Mobius.Endpoint`.
  """
  @spec setup_actions([Endpoint.t()]) :: Macro.output()
  defmacro setup_actions(endpoints) do
    quote bind_quoted: [endpoints: endpoints], location: :keep do
      import Mobius.Validations.ActionValidations

      alias Mobius.Actions

      resource = __MODULE__ |> Module.split() |> List.last()

      Enum.each(endpoints, fn endpoint ->
        name = endpoint.name
        param_names = Actions.get_arguments(endpoint)
        params_keyword = Actions.get_arguments_keyword(endpoint)

        def unquote(name)(unquote_splicing(param_names)) do
          Actions.execute(
            unquote(Macro.escape(endpoint)),
            unquote(params_keyword),
            unquote(resource)
          )
        end
      end)
    end
  end

  @spec execute(Endpoint.t(), Keyword.t(any()), atom() | binary()) :: any()
  def execute(%Endpoint{} = endpoint, params, resource) do
    rest_module = Module.concat([:Mobius, :Rest, resource])

    validators = get_validators(endpoint)

    case ActionValidations.validate_params(Keyword.get(params, :params, %{}), validators) do
      :ok ->
        param_values = Enum.map(params, fn {_name, value} -> value end)
        apply(rest_module, endpoint.name, [Bot.get_client!() | param_values])

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec get_arguments(Endpoint.t()) :: [Macro.input()]
  def get_arguments(%Endpoint{} = endpoint) do
    endpoint
    |> get_arguments_names()
    |> Enum.map(&Macro.var(&1, __MODULE__))
  end

  @spec get_arguments_keyword(Endpoint.t()) :: Keyword.t(Macro.input())
  def get_arguments_keyword(%Endpoint{} = endpoint) do
    endpoint
    |> get_arguments_names()
    |> Enum.map(fn argument -> {argument, Macro.var(argument, __MODULE__)} end)
  end

  defp get_arguments_names(%Endpoint{opts: _} = endpoint), do: endpoint.params ++ [:params]
  defp get_arguments_names(%Endpoint{} = endpoint), do: endpoint.params

  defp get_validators(%Endpoint{} = endpoint) do
    Enum.map(endpoint.opts, fn
      {name, :snowflake} -> ActionValidations.snowflake_validator(name)
      {name, :integer} -> ActionValidations.integer_validator(name)
      {name, {:integer, opts}} -> get_integer_range_validator(name, opts)
    end)
  end

  defp get_integer_range_validator(name, opts) do
    min = Keyword.fetch!(opts, :min)
    max = Keyword.fetch!(opts, :max)

    if min != nil and max != nil do
      ActionValidations.integer_range_validator(name, min, max)
    else
      ActionValidations.integer_validator(name)
    end
  end
end
