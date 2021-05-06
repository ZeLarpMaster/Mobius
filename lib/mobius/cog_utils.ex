defmodule Mobius.CogUtils do
  @moduledoc """
  A module of utilities for cogs such as formatting tables
  """

  @type categories :: [{String.t(), [{String.t(), String.t()}]}]

  @doc ~S"""
  Formats a list of tuples such that the spacing aligns the 2nd element of the inner tuple

  ## Example

      iex> data = [{"Cat1", [{"abc", "description"}, {"defghi", "something"}]}]
      iex> format_categories_list(data)
      "Cat1:\n  abc       description\n  defghi    something"

      iex> data = [{"Cat1", [{"abc", "description"}]}, {"Cat2", [{"defghi", "something"}]}]
      iex> format_categories_list(data)
      "Cat1:\n  abc       description\nCat2:\n  defghi    something"

      iex> format_categories_list([{"Cat1", []}], "empty category")
      "Cat1:\n  empty category"

      iex> format_categories_list([])
      ""
  """
  @spec format_categories_list(categories(), String.t()) :: String.t()
  def format_categories_list(list, empty_category \\ "nothing here") do
    column_width =
      list
      |> Enum.flat_map(fn {_category, rows} -> rows end)
      |> Enum.map(fn {name, _description} -> String.length(name) end)
      |> Enum.max(&>=/2, fn -> 0 end)

    list
    |> Enum.map(fn
      {category, []} -> "#{category}:\n  #{empty_category}"
      {category, rows} -> "#{category}:\n#{format_rows(rows, column_width)}"
    end)
    |> Enum.join("\n")
  end

  defp format_rows(rows, width) do
    rows
    |> Enum.map(fn {name, description} ->
      "  " <> String.pad_trailing(name, width) <> "    " <> description
    end)
    |> Enum.join("\n")
  end
end
