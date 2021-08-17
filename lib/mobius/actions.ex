defmodule Mobius.Actions do
  @moduledoc """
  Generation of Mobius actions

  This module contains the macros and functions necessary to generate Mobius
  actions from endpoint definitions.

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

      Enum.each(endpoints, fn endpoint ->
        name = endpoint.name
        param_names = Actions.get_arguments(endpoint)
        params_keyword = Actions.get_arguments_keyword(endpoint)

        def unquote(name)(unquote_splicing(param_names)) do
          Actions.execute(
            unquote(Macro.escape(endpoint)),
            unquote(params_keyword)
          )
        end
      end)
    end
  end

  @spec execute(Endpoint.t(), keyword()) :: any()
  def execute(%Endpoint{} = endpoint, params) do
    validators = get_validators(endpoint)

    path_params = params |> Keyword.get(:params, %{}) |> Keyword.new()

    case ActionValidations.validate_args(params ++ path_params, validators) do
      :ok ->
        Mobius.Rest.execute(endpoint, Bot.get_client!(), params)

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec get_arguments(Endpoint.t()) :: [Macro.input()]
  def get_arguments(%Endpoint{} = endpoint) do
    endpoint
    |> Endpoint.get_arguments_names()
    |> Enum.map(&Macro.var(&1, __MODULE__))
  end

  @spec get_arguments_keyword(Endpoint.t()) :: Keyword.t(Macro.input())
  def get_arguments_keyword(%Endpoint{} = endpoint) do
    endpoint
    |> Endpoint.get_arguments_names()
    |> Enum.map(fn argument -> {argument, Macro.var(argument, __MODULE__)} end)
  end

  @spec get_validators(Endpoint.t()) :: [{:atom, ActionValidations.validator()}]
  defp get_validators(%Endpoint{} = endpoint),
    do: get_param_validators(endpoint) ++ get_option_validators(endpoint)

  @spec get_param_validators(Endpoint.t()) :: [{:atom, ActionValidations.validator()}]
  defp get_param_validators(%Endpoint{} = endpoint) do
    Enum.map(endpoint.params, &type_tuple_to_validator_tuple/1)
  end

  @spec get_option_validators(Endpoint.t()) :: [{:atom, ActionValidations.validator()}]
  defp get_option_validators(%Endpoint{opts: nil}), do: []

  defp get_option_validators(%Endpoint{} = endpoint) do
    Enum.map(endpoint.opts, &type_tuple_to_validator_tuple/1)
  end

  @spec type_tuple_to_validator_tuple({atom(), ActionValidations.validator_type()}) ::
          {atom(), ActionValidations.validator()}
  defp type_tuple_to_validator_tuple({name, type}),
    do: {name, ActionValidations.get_validator(type)}
end
