defmodule Zodish.Helpers do
  @moduledoc ~S"""
  Common utility functions.
  """

  import Keyword, only: [keyword?: 1]
  import String, only: [capitalize: 1, slice: 2, ends_with?: 2]

  require Logger

  @doc ~S"""
  Returns a human-readable list as string from the given list.
  """
  @spec human_readable_list([value, ...], [option]) :: String.t()
        when value: String.t() | String.Chars.t(),
             option: {:conjunction, :and | :or}

  def human_readable_list(list, opts \\ [])
  def human_readable_list([head], _), do: "#{head}"

  def human_readable_list([_, _ | _] = list, opts) do
    conjunction =
      case Keyword.get(opts, :conjunction, :and) do
        :and -> "and"
        :or -> "or"
        value -> raise(ArgumentError, "Expected conjunction to be either :and or :or, got: #{inspect(value)}")
      end

    [last, second_last | rest] =
      list
      |> Enum.map(&to_string/1)
      |> :lists.reverse()

    rest
    |> :lists.reverse()
    |> Enum.concat(["#{second_last} #{conjunction} #{last}"])
    |> Enum.join(", ")
  end

  @doc ~S"""
  Alias to `Kernel.inspect/1`.
  """
  @spec i(value :: any()) :: String.t()

  def i(value), do: inspect(value)

  @doc ~S"""
  Infers the type of a value, returning its spec's AST.
  """
  @spec infer_type(value :: term()) :: Macro.t()

  def infer_type(value) when is_atom(value), do: value
  def infer_type(value) when is_binary(value), do: {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}
  def infer_type(value) when is_bitstring(value), do: [{:bitstring, [], []}]
  def infer_type(value) when is_boolean(value), do: value
  def infer_type(%Date{}), do: {{:., [], [{:__aliases__, [alias: false], [:Date]}, :t]}, [], []}
  def infer_type(%DateTime{}), do: {{:., [], [{:__aliases__, [alias: false], [:DateTime]}, :t]}, [], []}
  def infer_type(%Decimal{}), do: {{:., [], [{:__aliases__, [alias: false], [:Decimal]}, :t]}, [], []}
  def infer_type(value) when is_float(value), do: {:float, [], []}
  def infer_type(0), do: {:non_neg_integer, [], []}
  def infer_type(value) when is_integer(value) and value > 0, do: {:pos_integer, [], []}
  def infer_type(value) when is_integer(value), do: {:integer, [], []}
  def infer_type(value) when is_list(value), do: if(keyword?(value), do: {:keyword, [], []}, else: {:list, [], []})
  def infer_type(%mod{}), do: {:%, [], [{:__aliases__, [alias: false], [mod]}, {:%{}, [], []}]}
  def infer_type(%{__struct__: mod}), do: {:%, [], [{:__aliases__, [alias: false], [mod]}, {:%{}, [], []}]}
  def infer_type(value) when is_non_struct_map(value), do: {:map, [], []}
  def infer_type(value) when is_tuple(value), do: {:{}, [], Enum.map(Tuple.to_list(value), &infer_type/1)}
  def infer_type(value) when is_function(value), do: {:function, [], []}
  def infer_type(value) when is_pid(value), do: {:pid, [], []}
  def infer_type(value) when is_port(value), do: {:port, [], []}
  def infer_type(value) when is_reference(value), do: {:reference, [], []}
  def infer_type(_), do: {:term, [], []}

  @doc ~S"""
  Pluralizes a given word based on common English rules.

      iex> pluralize("is")
      "are"

      iex> pluralize("Was")
      "Were"

      iex> pluralize("cat")
      "cats"

      iex> pluralize("baby")
      "babies"

      iex> pluralize("box")
      "boxes"

      iex> pluralize("leaf")
      "leaves"

      iex> pluralize("man")
      "men"

      iex> pluralize("church")
      "churches"

  """
  @spec pluralize(word :: String.t()) :: String.t()

  @plural_exceptions [
    {"is", "are"},
    {"was", "were"},
    {"has", "have"},
    {"does", "do"},
    {"doesn't", "don't"}
  ]

  @plurals_index @plural_exceptions
                 |> Enum.flat_map(fn {s, p} -> [{s, p}, {capitalize(s), capitalize(p)}] end)
                 |> Enum.into(%{})

  def pluralize(word) do
    cond do
      Map.has_key?(@plurals_index, word) -> Map.fetch!(@plurals_index, word)
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

      iex> pluralize(1, "cat")
      "cat"

      iex> pluralize(0, "cat")
      "cats"

      iex> pluralize(2, "cat")
      "cats"

  """
  @spec pluralize(count :: non_neg_integer(), word :: String.t()) :: String.t()

  def pluralize(1, <<word::binary>>), do: word
  def pluralize(count, <<word::binary>>) when is_integer(count) and count >= 0, do: pluralize(word)

  @doc ~S"""
  Same as `Keyword.take/2` but the keys are sorted in the same order
  you provided them.

      iex> value =[foo: 1, bar: 2, baz: 3]
      iex> take_sorted(value, [:bar, :baz, :foo])
      [bar: 2, baz: 3, foo: 1]

  """
  def take_sorted([], _), do: []
  def take_sorted(_, []), do: []

  def take_sorted([{_, _} | _] = keyword, [_ | _] = keys) do
    keys
    |> Enum.reduce([], &fetch_prepend(keyword, &1, &2))
    |> :lists.reverse()
  end

  defp fetch_prepend(keyword, key, acc) do
    case Keyword.fetch(keyword, key) do
      {:ok, value} -> [{key, value} | acc]
      :error -> acc
    end
  end

  @doc ~S"""
  Returns the name of the given module without the "Elixir." prefix.

      iex> to_string(Zodish.Type.Map)
      "Elixir.Zodish.Type.Map"

      iex> to_mod_name(Zodish.Type.Map)
      "Zodish.Type.Map"

  """
  @spec to_mod_name(mod :: module()) :: String.t()

  def to_mod_name(mod)
      when is_atom(mod),
      do: String.replace(to_string(mod), ~r/^Elixir\./, "")

  @doc ~S"""
  Returns the type of the given value.
  """
  @spec typeof(value) :: String.t()
        when value:
               nil
               | boolean()
               | atom()
               | binary()
               | bitstring()
               | float()
               | integer()
               | list()
               | keyword()
               | struct()
               | map()
               | tuple()
               | function()
               | pid()
               | port()
               | reference()

  def typeof(nil), do: "nil"
  def typeof(value) when is_atom(value), do: "atom"
  def typeof(value) when is_binary(value), do: "string"
  def typeof(value) when is_bitstring(value), do: "bitstring"
  def typeof(value) when is_boolean(value), do: "boolean"
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

  @doc ~S"""
  Prints a warning message the returns the value given as first
  argument.
  """
  @spec warn(value, message :: String.t()) :: value
        when value: any()

  def warn(value, message) do
    Logger.warning("[Zodish] #{message}")
    value
  end
end
