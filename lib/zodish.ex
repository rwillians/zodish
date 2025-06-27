defmodule Zodish do
  @moduledoc ~S"""
  Zodish is a schema parser and validator library heavily inspired by
  JavaScript's Zod.
  """

  alias Zodish.Type.Any, as: TAny
  alias Zodish.Type.Atom, as: TAtom
  alias Zodish.Type.Boolean, as: TBoolean
  alias Zodish.Type.DateTime, as: TDateTime
  alias Zodish.Type.String, as: TString

  @doc ~S"""
  Parses a value based on the given type.

      iex> Z.string()
      iex> |> Z.parse("Hello, World!")
      {:ok, "Hello, World!"}

  """
  @spec parse(type :: Zodish.Type.t(), value :: any()) ::
          {:ok, any()}
          | {:error, Zodish.Issue.t()}

  defdelegate parse(type, value), to: Zodish.Type

  #
  #   CORE TYPES
  #   Keep them sorted alphabetically!
  #

  @doc ~S"""
  Defines a type that accepts any value.

      iex> Z.any()
      iex> |> Z.parse("string")
      {:ok, "string"}

      iex> Z.any()
      iex> |> Z.parse(123)
      {:ok, 123}

      iex> Z.any()
      iex> |> Z.parse(%{key: "value"})
      {:ok, %{key: "value"}}

      iex> Z.any()
      iex> |> Z.parse({:foo, :bar})
      {:ok, {:foo, :bar}}

  """
  @spec any() :: TAny.t()

  defdelegate any(), to: TAny, as: :new

  @doc ~S"""
  Defines an atom type.

      iex> Z.atom()
      iex> |> Z.parse(:foo)
      {:ok, :foo}

  ## Options

  You can use `:coerce` to cast the given string into an atom.

      iex> Z.atom(coerce: true)
      iex> |> Z.parse("foo")
      {:ok, :foo}

  By default, `:coerce` will only cast strings for existing atoms
  since BEAM has a limited number of atom.

      iex> Z.atom(coerce: true)
      iex> |> Z.parse("alksdhfwejh")
      {:error, %Zodish.Issue{message: "Cannot coerce string \"alksdhfwejh\" into an existing atom"}}

  If you want to allow unsafe coercion of any string into an atom, you
  can set `:coerce` to `:unsafe`.

      iex> Z.atom(coerce: :unsafe)
      iex> |> Z.parse("lskdjfalsdjf")
      {:ok, :lskdjfalsdjf}

  """
  @spec atom(opts :: [option]) :: TAtom.t()
        when option: {:coerce, boolean() | :unsafe}

  defdelegate atom(opts \\ []), to: TAtom, as: :new

  @doc ~S"""
  Defines a boolean type.

      iex> Z.boolean()
      iex> |> Z.parse(true)
      {:ok, true}

  ## Options

  You can use `:coerce` to cast the given value into a boolean.

      iex> Z.boolean(coerce: true)
      iex> |> Z.parse("true")
      {:ok, true}

  The accepted boolean-like values are:

  | value        | coerced to |
  | :----------- | :--------- |
  | `"true"`     | `true`     |
  | `"1"`        | `true`     |
  | `1`          | `true`     |
  | `"yes"`      | `true`     |
  | `"y"`        | `true`     |
  | `"on"`       | `true`     |
  | `"enabled"`  | `true`     |
  | `"false"`    | `false`    |
  | `"0"`        | `false`    |
  | `0`          | `false`    |
  | `"no"`       | `false`    |
  | `"n"`        | `false`    |
  | `"off"`      | `false`    |
  | `"disabled"` | `false`    |
  """
  @spec boolean(opts :: [option]) :: TBoolean.t()
        when option: {:coerce, boolean()}

  defdelegate boolean(opts \\ []), to: TBoolean, as: :new

  @doc ~S"""
  Defines a date-time type.

      iex> Z.date_time()
      iex> |> Z.parse(~U[2025-06-27T12:00:00.000Z])
      {:ok, ~U[2025-06-27T12:00:00.000Z]}

  ## Options

  You can use `:coerce` to cast the given value into a DateTime.

      iex> Z.date_time(coerce: true)
      iex> |> Z.parse("2025-06-27T12:00:00.000Z")
      {:ok, ~U[2025-06-27T12:00:00.000Z]}

  """
  @spec date_time(opts :: [option]) :: TDateTime.t()
        when option: {:coerce, boolean()}
        
  defdelegate date_time(opts \\ []), to: TDateTime, as: :new

  @doc ~S"""
  Defines a string type.

      iex> Z.string()
      iex> |> Z.parse("Hello, World!")
      {:ok, "Hello, World!"}

  ## Options

  You can use `:exact_length`, `:min_length` and `:max_length` to
  constrain the length of the string.

      iex> Z.string(exact_length: 3)
      iex> |> Z.parse("foobar")
      {:error, %Zodish.Issue{message: "Expected string to have exactly 3 characters, got 6 characters"}}

      iex> Z.string(min_length: 1)
      iex> |> Z.parse("")
      {:error, %Zodish.Issue{message: "Expected string to have at least 1 character, got 0 characters"}}

      iex> Z.string(max_length: 3)
      iex> |> Z.parse("foobar")
      {:error, %Zodish.Issue{message: "Expected string to have at most 3 characters, got 6 characters"}}

  You can also use `:trim` to trim leading and trailing whitespaces
  from the string before validation.

      iex> Z.string(trim: true, min_length: 1)
      iex> |> Z.parse("   ")
      {:error, %Zodish.Issue{message: "Expected string to have at least 1 character, got 0 characters"}}

  You can use `:starts_with` and `:ends_with` to check if the string
  starts with a given prefix or ends with a given suffix.

      iex> Z.string(starts_with: "sk_")
      iex> |> Z.parse("pk_123")
      {:error, %Zodish.Issue{message: "Expected string to start with \"sk_\", got \"pk_123\""}}

      iex> Z.string(ends_with: "bar")
      iex> |> Z.parse("fizzbuzz")
      {:error, %Zodish.Issue{message: "Expected string to end with \"bar\", got \"fizzbuzz\""}}

  You can use `:regex` to validate the string against a regular
  expression.

      iex> Z.string(regex: ~r/^\d+$/)
      iex> |> Z.parse("123abc")
      {:error, %Zodish.Issue{message: "Expected string to match /^\\d+$/, got \"123abc\""}}

  You can use `:coerce` to cast the given value into a string before
  validation.

      iex> Z.string(coerce: true)
      iex> |> Z.parse(123)
      {:ok, "123"}

  """
  @spec string(opts :: [option]) :: TString.t()
        when option:
              {:coerce, boolean()}
              | {:trim, boolean()}
              | {:downcase, boolean()}
              | {:upcase, boolean()}
              | {:exact_length, non_neg_integer()}
              | {:exact_length, Zodish.Option.t(non_neg_integer())}
              | {:min_length, non_neg_integer()}
              | {:min_length, Zodish.Option.t(non_neg_integer())}
              | {:max_length, non_neg_integer()}
              | {:max_length, Zodish.Option.t(non_neg_integer())}
              | {:starts_with, String.t()}
              | {:starts_with, Zodish.Option.t(String.t())}
              | {:ends_with, String.t()}
              | {:ends_with, Zodish.Option.t(String.t())}
              | {:regex, Regex.t()}
              | {:regex, Zodish.Option.t(Regex.t())}

  defdelegate string(opts \\ []), to: TString, as: :new
end
