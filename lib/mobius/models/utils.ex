defmodule Mobius.Models.Utils do
  @moduledoc false

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
end
