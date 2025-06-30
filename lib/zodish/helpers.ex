defmodule Zodish.Helpers do
  @moduledoc ~S"""
  Common utility functions.
  """

  import Keyword, only: [keyword?: 1]
  import String, only: [slice: 2, ends_with?: 2]

  @doc ~S"""
  Pluralizes a given word based on common English rules.
  """
  @spec pluralize(word :: String.t()) :: String.t()

  def pluralize(word) do
    cond do
      ends_with?(word, "y") -> slice(word, 0..-2//1) <> "ies"
      ends_with?(word, "o") -> word <> "es"
      ends_with?(word, "s") -> word <> "es"
      ends_with?(word, "x") -> word <> "es"
      ends_with?(word, "z") -> word <> "es"
      ends_with?(word, "ch") -> word <> "es"
      ends_with?(word, "sh") -> word <> "es"
      ends_with?(word, "f") -> slice(word, 0..-2//1) <> "ves"
      ends_with?(word, "fe") -> slice(word, 0..-3//1) <> "ves"
      ends_with?(word, "man") -> slice(word, 0..-4//1) <> "men"
      true -> word <> "s"
    end
  end

  @doc ~S"""
  Pluralizes a word based on the given count.

      iex> Zodish.Helpers.pluralize(1, "cat")
      "cat"

      iex> Zodish.Helpers.pluralize(0, "cat")
      "cats"

      iex> Zodish.Helpers.pluralize(2, "cat")
      "cats"

  """
  @spec pluralize(count :: non_neg_integer(), word :: String.t()) :: String.t()

  def pluralize(1, <<word::binary>>), do: word
  def pluralize(count, <<word::binary>>) when is_integer(count) and count >= 0, do: pluralize(word)

  @doc ~S"""
  Returns the name of the given module without the "Elixir." prefix.

      iex> to_string(Zodish.Type.Map)
      "Elixir.Zodish.Type.Map"

      iex> Zodish.Helpers.to_mod_name(Zodish.Type.Map)
      "Zodish.Type.Map"

  """
  @spec to_mod_name(mod :: module()) :: String.t()

  def to_mod_name(mod)
      when is_atom(mod),
      do: String.replace(to_string(mod), ~r/^Elixir\./, "")

  @doc ~S"""
  Returns the type of the given value.
  """
  @spec typeof(value :: any()) :: String.t()

  def typeof(nil), do: "nil"
  def typeof(value) when is_boolean(value), do: "boolean"
  def typeof(value) when is_atom(value), do: "atom"
  def typeof(value) when is_binary(value), do: "string"
  def typeof(value) when is_bitstring(value), do: "bitstring"
  def typeof(value) when is_float(value), do: "float"
  def typeof(value) when is_integer(value), do: "integer"
  def typeof(value) when is_list(value), do: if(keyword?(value), do: "keyword", else: "list")
  def typeof(%mod{}), do: "%#{to_mod_name(mod)}{}"
  def typeof(%{__struct__: mod}), do: "%#{to_mod_name(mod)}{}"
  def typeof(value) when is_map(value), do: "map"
  def typeof(value) when is_tuple(value), do: "tuple"
  def typeof(value) when is_function(value), do: "function"
  def typeof(value) when is_pid(value), do: "pid"
  def typeof(value) when is_port(value), do: "port"
  def typeof(value) when is_reference(value), do: "reference"
end
