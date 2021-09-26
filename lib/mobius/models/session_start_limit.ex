defmodule Mobius.Models.SessionStartLimit do
  @moduledoc """
  Struct for the session start limit given by GET /gateway/bot

  Related documentation: https://discord.com/developers/docs/topics/gateway#get-gateway-bot
  """

  import Mobius.Model

  @behaviour Mobius.Model

  defstruct [:total, :remaining, :reset_after, :max_concurrency]

  @type t :: %__MODULE__{
          total: non_neg_integer(),
          remaining: non_neg_integer(),
          reset_after: non_neg_integer(),
          max_concurrency: pos_integer()
        }

  @doc """
  Parses the given term into a `t:t()` if possible; returns nil otherwise

  ## Examples

      iex> alias Mobius.Models.SessionStartLimit
      iex> parse("not a map")
      nil
      iex> parse(%{})
      %SessionStartLimit{}
      iex> parse(%{"total" => 10, "remaining" => 9, "reset_after" => 0, "max_concurrency" => 1})
      %SessionStartLimit{max_concurrency: 1, remaining: 9, reset_after: 0, total: 10}
  """
  @impl true
  @spec parse(any) :: t() | nil
  def parse(map) when is_map(map) do
    %__MODULE__{}
    |> add_field(map, :total)
    |> add_field(map, :remaining)
    |> add_field(map, :reset_after)
    |> add_field(map, :max_concurrency)
  end

  def parse(_), do: nil
end
