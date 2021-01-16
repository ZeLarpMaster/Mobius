defmodule Mobius.Models.Utils do
  @moduledoc false

  @doc """
  Adds a field to the struct with the value given by map_key in the map

  The value goes through the parser function before being put in the struct
  This will raise an exception if the struct_key isn't a part of the struct
  """
  @spec add_field(struct, map, any, atom, (any -> any)) :: struct when struct: struct()
  def add_field(struct, map, map_key, struct_key, parser \\ fn x -> x end) do
    value =
      map
      |> Map.get(map_key)
      |> parser.()

    struct!(struct, [{struct_key, value}])
  end
end
