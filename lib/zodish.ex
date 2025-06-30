defmodule Zodish do
  @moduledoc ~S"""
  Zodish is a schema parser and validation library heavily inspired by
  JavaScript's Zod.
  """

  alias Zodish.Type.Any, as: TAny
  alias Zodish.Type.Atom, as: TAtom
  alias Zodish.Type.Boolean, as: TBoolean
  alias Zodish.Type.Date, as: TDate
  alias Zodish.Type.DateTime, as: TDateTime
  alias Zodish.Type.Float, as: TFloat
  alias Zodish.Type.Integer, as: TInteger
  alias Zodish.Type.List, as: TList
  alias Zodish.Type.Literal, as: TLiteral
  alias Zodish.Type.Map, as: TMap
  alias Zodish.Type.Number, as: TNumber
  alias Zodish.Type.Optional, as: TOptional
  alias Zodish.Type.String, as: TString
  alias Zodish.Type.Struct, as: TStruct
  alias Zodish.Type.Tuple, as: TTuple

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
  Defines a date type.

      iex> Z.date()
      iex> |> Z.parse(~D[2025-06-27])
      {:ok, ~D[2025-06-27]}

  ## Options

  You can use `:coerce` to cast the given value into a Date.

      iex> Z.date(coerce: true)
      iex> |> Z.parse("2025-06-27")
      {:ok, ~D[2025-06-27]}

  """
  @spec date(opts :: [option]) :: TDate.t()
        when option: {:coerce, boolean()}

  defdelegate date(opts \\ []), to: TDate, as: :new

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
  Defines a float type.

      iex> Z.float()
      iex> |> Z.parse(3.14)
      {:ok, 3.14}

  ## Options

  You can use `:gt`, `:gte`, `:lt` and `:lte` to constrain the allowed
  values.

      iex> Z.float(gt: 0.0)
      iex> |> Z.parse(0.0)
      {:error, %Zodish.Issue{message: "Expected a float greater than 0.0, got 0.0"}}

      iex> Z.float(gte: 1.0)
      iex> |> Z.parse(0.5)
      {:error, %Zodish.Issue{message: "Expected a float greater than or equal to 1.0, got 0.5"}}

      iex> Z.float(lt: 1.0)
      iex> |> Z.parse(1.1)
      {:error, %Zodish.Issue{message: "Expected a float less than 1.0, got 1.1"}}

      iex> Z.float(lte: 1.0)
      iex> |> Z.parse(1.1)
      {:error, %Zodish.Issue{message: "Expected a float less than or equal to 1.0, got 1.1"}}

  You can use `:coerce` to cast the given value into a float before
  validation.

      iex> Z.float(coerce: true)
      iex> |> Z.parse("3.14")
      {:ok, 3.14}

      iex> Z.float(coerce: true)
      iex> |> Z.parse("123")
      {:ok, 123.0}

  """
  @spec float(opts :: [option]) :: TFloat.t()
        when option:
               {:coerce, boolean()}
               | {:gt, float()}
               | {:gt, Zodish.Option.t(float())}
               | {:gte, float()}
               | {:gte, Zodish.Option.t(float())}
               | {:lt, float()}
               | {:lt, Zodish.Option.t(float())}
               | {:lte, float()}
               | {:lte, Zodish.Option.t(float())}

  defdelegate float(opts \\ []), to: TFloat, as: :new

  @doc ~S"""
  Defines a integer type.

      iex> Z.integer()
      iex> |> Z.parse(3)
      {:ok, 3}

  ## Options

  You can use `:gt`, `:gte`, `:lt` and `:lte` to constrain the allowed
  values.

      iex> Z.integer(gt: 0)
      iex> |> Z.parse(0)
      {:error, %Zodish.Issue{message: "Expected a integer greater than 0, got 0"}}

      iex> Z.integer(gte: 0)
      iex> |> Z.parse(-1)
      {:error, %Zodish.Issue{message: "Expected a integer greater than or equal to 0, got -1"}}

      iex> Z.integer(lt: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "Expected a integer less than 1, got 2"}}

      iex> Z.integer(lte: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "Expected a integer less than or equal to 1, got 2"}}

  You can use `:coerce` to cast the given value into a integer before
  validation.

      iex> Z.integer(coerce: true)
      iex> |> Z.parse("123")
      {:ok, 123}

      iex> Z.integer(coerce: true)
      iex> |> Z.parse("123.678")
      {:ok, 123}

  If a float is provided, it will be truncated to an integer.

      iex> Z.integer(coerce: true)
      iex> |> Z.parse(123.678)
      {:ok, 123}

  """
  @spec integer(opts :: [option]) :: TInteger.t()
        when option:
               {:coerce, boolean()}
               | {:gt, integer()}
               | {:gt, Zodish.Option.t(integer())}
               | {:gte, integer()}
               | {:gte, Zodish.Option.t(integer())}
               | {:lt, integer()}
               | {:lt, Zodish.Option.t(integer())}
               | {:lte, integer()}
               | {:lte, Zodish.Option.t(integer())}

  defdelegate integer(opts \\ []), to: TInteger, as: :new

  @doc ~S"""
  Defines a list type.

      iex> Z.list(Z.integer())
      iex> |> Z.parse([1, 2, 3])
      {:ok, [1, 2, 3]}

      iex> Z.list(Z.integer())
      iex> |> Z.parse([1, 2, "3"])
      {:error, %Zodish.Issue{
        message: "One or more items of the list did not match the expected type",
        parse_score: 3,
        issues: [%Zodish.Issue{path: [2], message: "Expected a integer, got string"}]
      }}

  ## Options

  You can use `:exact_length`, `:min_length` and `:max_length` to
  constrain the length of the list.

      iex> Z.list(Z.integer(), exact_length: 3)
      iex> |> Z.parse([1, 2, 3, 4])
      {:error, %Zodish.Issue{message: "Expected list to have exactly 3 items, got 4 items"}}

      iex> Z.list(Z.integer(), min_length: 1)
      iex> |> Z.parse([])
      {:error, %Zodish.Issue{message: "Expected list to have at least 1 item, got 0 items"}}

      iex> Z.list(Z.integer(), max_length: 3)
      iex> |> Z.parse([1, 2, 3, 4])
      {:error, %Zodish.Issue{message: "Expected list to have at most 3 items, got 4 items"}}

  """
  @spec list(inner_type :: Zodish.Type.t(), opts :: [option]) :: TList.t()
        when option:
              {:exact_length, non_neg_integer()}
              | {:exact_length, Zodish.Option.t(non_neg_integer())}
              | {:min_length, non_neg_integer()}
              | {:min_length, Zodish.Option.t(non_neg_integer())}
              | {:max_length, non_neg_integer()}
              | {:max_length, Zodish.Option.t(non_neg_integer())}

  defdelegate list(inner_type, opts \\ []), to: TList, as: :new

  @doc ~S"""
  Defines a type that only accepts a specific value.

      iex> Z.literal("foo")
      iex> |> Z.parse("foo")
      {:ok, "foo"}

      iex> Z.literal(42)
      iex> |> Z.parse(51)
      {:error, %Zodish.Issue{message: "Expected to be 42, got 51"}}

  """
  @spec literal(value :: any()) :: TLiteral.t()

  defdelegate literal(value), to: TLiteral, as: :new

  @doc ~S"""
  Defines a map type.

      iex> Z.map(%{name: Z.string(), age: Z.integer(gte: 18)})
      iex> |> Z.parse(%{name: "John Doe", age: 27})
      {:ok, %{name: "John Doe", age: 27}}

  The keys of the parsed map will always be atoms.

      iex> Z.map(%{name: Z.string(), age: Z.integer(gte: 18)})
      iex> |> Z.parse(%{"name" => "John Doe", "age" => 27})
      {:ok, %{name: "John Doe", age: 27}}

  ## Options

  You can specify one of two behaviors for how to handle unknown fields
  in the input value:
  - `:strip` (default) - Unknown fields will be ignored and not included
    in the parsed result;
  - `:strict` - Unknown fields will cause a validation error.

      iex> Z.map(:strip, %{name: Z.string(), age: Z.integer(gte: 18)})
      iex> |> Z.parse(%{name: "John Doe", email: "johndoe@gmail.com", age: 27})
      {:ok, %{name: "John Doe", age: 27}}

      iex> Z.map(:strict, %{name: Z.string(), age: Z.integer(gte: 18)})
      iex> |> Z.parse(%{name: "John Doe", email: "johndoe@gmail.com", age: 27})
      {:error, %Zodish.Issue{
        message: "One or more fields failed validation",
        parse_score: 3,
        issues: [%Zodish.Issue{path: ["email"], message: "Unknown field"}]
      }}

  If you need to validate a map where you don't know what keys will be
  present, then use `Z.record/1` instead.
  """
  @spec map(mode, shape) :: TMap.t()
        when mode: :strip | :strict,
             shape: %{required(atom()) => Zodish.Type.t()}

  defdelegate map(mode \\ :strip, shape), to: TMap, as: :new

  @doc ~S"""
  Defines a number type.

      iex> Z.number()
      iex> |> Z.parse(3)
      {:ok, 3}

      iex> Z.number()
      iex> |> Z.parse(3.14)
      {:ok, 3.14}

  ## Options

  You can use `:gt`, `:gte`, `:lt` and `:lte` to constrain the allowed
  values.

      iex> Z.number(gt: 0)
      iex> |> Z.parse(0)
      {:error, %Zodish.Issue{message: "Expected a number greater than 0, got 0"}}

      iex> Z.number(gte: 0)
      iex> |> Z.parse(-1)
      {:error, %Zodish.Issue{message: "Expected a number greater than or equal to 0, got -1"}}

      iex> Z.number(lt: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "Expected a number less than 1, got 2"}}

      iex> Z.number(lte: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "Expected a number less than or equal to 1, got 2"}}

  You can use `:coerce` to cast the given value into a number before
  validation.

      iex> Z.number(coerce: true)
      iex> |> Z.parse("123")
      {:ok, 123}

      iex> Z.number(coerce: true)
      iex> |> Z.parse("123.678")
      {:ok, 123.678}

  """
  @spec number(opts :: [option]) :: TInteger.t()
        when option:
               {:coerce, boolean()}
               | {:gt, number()}
               | {:gt, Zodish.Option.t(number())}
               | {:gte, number()}
               | {:gte, Zodish.Option.t(number())}
               | {:lt, number()}
               | {:lt, Zodish.Option.t(number())}
               | {:lte, number()}
               | {:lte, Zodish.Option.t(number())}

  defdelegate number(opts \\ []), to: TNumber, as: :new

  @doc ~S"""
  Makes a given inner type optional, where you can also define a
  default value to be used when the actual value resolves to `nil`.

      iex> Z.integer()
      iex> |> Z.parse(nil)
      {:error, %Zodish.Issue{message: "Is required"}}

      iex> Z.optional(Z.integer())
      iex> |> Z.parse(nil)
      {:ok, nil}

  ## Options

  You can use `:default` to define a default value to be used when
  the actual value resolves to `nil`.

      iex> Z.optional(Z.integer(), default: 42)
      iex> |> Z.parse(nil)
      {:ok, 42}

      iex> Z.optional(Z.integer(), default: fn -> 42 end)
      iex> |> Z.parse(nil)
      {:ok, 42}

  The default value must satisfy the inner type of the `Zodish.Type.Optional`.
  If you provide a default value other than a function that doesn't
  satisfy the inner type, it will raise an `ArgumentError`.

      iex> Z.optional(Z.integer(), default: "not a number")
      ** (ArgumentError) The default value must satisfy the inner type of Zodish.Type.Optional

  If you provide a function as the default value though and it returns
  a value that doesn't satisfy the inner type, it will return a
  `Zodish.Issue` since this check cannot be done at compile time.

      iex> Z.optional(Z.integer(), default: fn -> "abc" end)
      iex> |> Z.parse(nil)
      {:error, %Zodish.Issue{message: "Expected a integer, got string"}}

  """
  @spec optional(inner_type :: Zodish.Type.t(), opts :: [option]) :: TOptional.t()
        when option: {:default, (-> any()) | any() | nil}

  defdelegate optional(inner_type, opts \\ []), to: TOptional, as: :new

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

  @doc ~S"""
  Defines a struct type.

      iex> Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> })
      iex> |> Z.parse(%{
      iex>   line_1: "123 Main St",
      iex>   line_2: "Apt 4B",
      iex>   city: "Springfield",
      iex>   state: "IL",
      iex>   zip: "62701"
      iex> })
      {:ok, %Address{
        line_1: "123 Main St",
        line_2: "Apt 4B",
        city: "Springfield",
        state: "IL",
        zip: "62701"
      }}

  If your Zodish type includes a key that doesn't exist in the struct,
  then an `ArgumentError` will be raised.

      iex> Z.struct(Address, %{name: Z.string()})
      ** (ArgumentError) The shape key :name doesn't exist in struct ZodishTest.Address

  A Zodish struct type works like a Map type in :strict mode, meaning
  if a field that isn't present in the struct is provided in the input,
  then it will fail validation.

      iex> Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> })
      iex> |> Z.parse(%{
      iex>   name: "John Doe",
      iex>   line_1: "123 Main St",
      iex>   line_2: "Apt 4B",
      iex>   city: "Springfield",
      iex>   state: "IL",
      iex>   zip: "62701"
      iex> })
      {:error, %Zodish.Issue{
        message: "One or more fields failed validation",
        parse_score: 6,
        issues: [%Zodish.Issue{path: ["name"], message: "Unknown field"}]
      }}

  """
  @spec struct(mod, shape) :: TStruct.t()
        when mod: module,
             shape: %{required(atom()) => Zodish.Type.t()}

  defdelegate struct(mod, shape), to: TStruct, as: :new

  @doc ~S"""
  Defines a tuple type.

      iex> Z.tuple([Z.atom(), Z.integer()])
      iex> |> Z.parse({:ok, 123})
      {:ok, {:ok, 123}}

      iex> Z.tuple([Z.atom(), Z.integer(), Z.string()])
      iex> |> Z.parse({:ok, "abc"})
      {:error, %Zodish.Issue{message: "Expected a tuple of length 3, got length 2"}}

      iex> Z.tuple([Z.atom(), Z.integer()])
      iex> |> Z.parse({:ok, "abc"})
      {:error, %Zodish.Issue{
        message: "One or more elements of the tuple did not match the expected type",
        parse_score: 1,
        issues: [%Zodish.Issue{path: [1], message: "Expected a integer, got string"}],
      }}

  """
  @spec tuple(elements :: [Zodish.Type.t(), ...]) :: TTuple.t()

  defdelegate tuple(elements), to: TTuple, as: :new
end
