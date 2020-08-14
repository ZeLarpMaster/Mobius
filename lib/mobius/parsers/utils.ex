defmodule Mobius.Parsers.Utils do
  @moduledoc false

  alias Mobius.Models.Snowflake

  @type path :: String.t() | nil
  @type error :: {:missing_key, String.t(), String.t()} | :invalid_input
  @type result :: map | list(map) | {:error, error()}
  @type input :: map | list(map)

  @type required :: :required | :optional
  @type source :: String.t() | {:via, String.t(), module, atom}
  @type spec :: [{required(), atom, source()}]

  @spec filter_nil(Enumerable.t()) :: Enumerable.t()
  def filter_nil(enumerable), do: Enum.filter(enumerable, fn x -> x != nil end)

  @spec parse_flags(integer, [atom | nil], [atom]) :: [atom]
  def parse_flags(num, flags, out \\ [])
  def parse_flags(_num, [], out), do: out
  def parse_flags(0, _flags, out), do: out

  def parse_flags(num, [flag | flags], out) do
    import Bitwise
    out = if (num &&& 1) == 1 and flag != nil, do: [flag | out], else: out
    parse_flags(num >>> 1, flags, out)
  end

  @spec parse_iso8601(String.t(), path()) :: DateTime.t()
  def parse_iso8601(timestamp, path \\ nil) do
    case DateTime.from_iso8601(timestamp) do
      {:error, error} -> throw({:invalid_value, error, path})
      {:ok, datetime, _offset} -> datetime
    end
  end

  @spec parse_snowflake(String.t(), path()) :: Snowflake.t()
  def parse_snowflake(id, path \\ nil) when is_binary(id) do
    case Snowflake.string_to_snowflake(id) do
      :invalid_input -> throw({:invalid_value, id, path})
      snowflake -> snowflake
    end
  end

  @spec parse(spec, input(), path()) :: result()
  def parse(spec, value, nil) do
    # Only the initial call catches errors so a throw shortcircuits to here and stops the parsing
    try do
      # The path is used to trace deep errors and looks like `v.key1[0].key2`
      parse(spec, value, "v")
    catch
      {:missing, key, path} -> {:error, {:missing_key, key, path}}
      {:invalid_value, _value, _path} = error -> {:error, error}
      {:error, _} = error -> error
    end
  end

  def parse(spec, map, path) when is_map(map) do
    spec
    |> Enum.map(&parse_key(&1, map, path))
    # nil is used to *not* add a value to the resulting map
    |> filter_nil()
    |> Map.new()
  end

  def parse(spec, list, path) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {v, i} -> parse(spec, v, path <> "[#{i}]") end)
  end

  def parse(_spec, _value, _path), do: {:error, :invalid_input}

  defp parse_key({required, key, source}, map, path) do
    map_key = get_map_key(source)

    cond do
      Map.has_key?(map, map_key) -> {key, get_key(source, map, path <> ".#{key}")}
      required == :optional -> nil
      true -> throw({:missing, map_key, path})
    end
  end

  defp get_map_key({:via, map_key, _, _}), do: map_key
  defp get_map_key(map_key), do: map_key

  defp get_key(map_key, map, _path) when is_binary(map_key) do
    Map.fetch!(map, map_key)
  end

  defp get_key({:via, map_key, module, parser}, map, path) when is_binary(map_key) do
    case Map.fetch!(map, map_key) do
      nil -> nil
      [] -> []
      value when is_list(value) -> apply_map(module, parser, value, path)
      value -> apply(module, parser, [value, path])
    end
  end

  defp apply_map(module, parser, value, path) do
    value
    |> Enum.with_index()
    |> Enum.map(fn {v, i} -> apply(module, parser, [v, path <> "[#{i}]"]) end)
  end
end
