defmodule Mobius.Models.Utils do
  @moduledoc false

  alias Mobius.Core.Bitflags

  @doc """
  Adds a field to the struct with the value given by struct_key in the map

  Note that the struct key is an atom,
  but is converted to a String before being used as a key in the map

  The value goes through the parser function before being put in the struct
  This will raise an exception if the struct_key isn't a part of the struct
  """
  @spec add_field(struct, map, atom, (any -> any)) :: struct when struct: struct()
  def add_field(struct, map, struct_key, parser \\ fn x -> x end) do
    value =
      map
      |> Map.get(Atom.to_string(struct_key))
      |> parser.()

    struct!(struct, [{struct_key, value}])
  end

  @spec parse_list(any, (any -> output)) :: [output] | nil when output: var
  def parse_list(list, parser) when is_list(list), do: Enum.map(list, parser)
  def parse_list(_list, _parser), do: nil

  @doc "Parse strings of numbers into integer, returns nil for any other value"
  @spec parse_integer(any) :: integer | nil
  def parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> nil
    end
  end

  def parse_integer(_value), do: nil

  def parse_flags(value, flags) when is_integer(value), do: Bitflags.parse_bitflags(value, flags)
  def parse_flags(_value, _flags), do: nil
end
