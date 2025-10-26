defmodule Zodish do
  @moduledoc ~S"""
  Zodish is a schema parser and validation library heavily inspired by
  JavaScript's Zod.
  """

  import Zodish.Helpers, only: [i: 1]

  alias Zodish.Type.Any, as: TAny
  alias Zodish.Type.Atom, as: TAtom
  alias Zodish.Type.Boolean, as: TBoolean
  alias Zodish.Type.Date, as: TDate
  alias Zodish.Type.DateTime, as: TDateTime
  alias Zodish.Type.Decimal, as: TDecimal
  alias Zodish.Type.Email, as: TEmail
  alias Zodish.Type.Enum, as: TEnum
  alias Zodish.Type.Float, as: TFloat
  alias Zodish.Type.Integer, as: TInteger
  alias Zodish.Type.List, as: TList
  alias Zodish.Type.Literal, as: TLiteral
  alias Zodish.Type.Map, as: TMap
  alias Zodish.Type.Number, as: TNumber
  alias Zodish.Type.Optional, as: TOptional
  alias Zodish.Type.Record, as: TRecord
  alias Zodish.Type.Refine, as: Refine
  alias Zodish.Type.String, as: TString
  alias Zodish.Type.Struct, as: TStruct
  alias Zodish.Type.Transform, as: Transform
  alias Zodish.Type.Tuple, as: TTuple
  alias Zodish.Type.Union, as: TUnion
  alias Zodish.Type.URI, as: TUri
  alias Zodish.Type.Uuid, as: TUuid

  @on_unsupported_coercion Application.compile_env!(:zodish, :on_unsupported_coercion)

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

  @doc ~S"""
  Same as `parse/1` but raises an error if failed to parse the given
  params.

      iex> Z.string()
      iex> |> Z.parse!("Hello, World!")
      "Hello, World!"

      iex> Z.string()
      iex> |> Z.parse!(123)
      ** (Zodish.Issue) expected a string, got integer

  """
  @spec parse!(type, value) :: term()
        when type: Zodish.Type.t(),
             value: term()

  def parse!(type, value) do
    case parse(type, value) do
      {:ok, parsed} -> parsed
      {:error, issue} -> raise(issue)
    end
  end

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
      {:error, %Zodish.Issue{message: "cannot coerce string \"alksdhfwejh\" into an existing atom"}}

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
  Enables coercion for the given type.

      iex> Z.integer()
      iex> |> Z.coerce()
      iex> |> Z.parse("123")
      {:ok, 123}

  If the given type doesn't support coercion but it encapsulates an
  inner type, then the coercion will be applied to the inner type.

      iex> Z.optional(Z.integer())
      %Zodish.Type.Optional{
        inner_type: %Zodish.Type.Integer{coerce: false}
      }

      iex> Z.optional(Z.integer())
      iex> |> Z.coerce()
      %Zodish.Type.Optional{
        inner_type: %Zodish.Type.Integer{coerce: true}
      }

      iex> Z.optional(Z.integer())
      iex> |> Z.coerce()
      iex> |> Z.parse("123")
      {:ok, 123}

  """
  @spec coerce(type, value :: boolean() | :unsafe) :: type
        when type: TAtom.t()
  @spec coerce(type, value :: boolean()) :: type
        when type: struct()

  def coerce(type, value \\ true)
  def coerce(%mod{coerce: _} = type, value), do: apply(mod, :coerce, [type, value])
  def coerce(%_{inner_type: inner_type} = type, value), do: %{type | inner_type: coerce(inner_type, value)}
  case @on_unsupported_coercion do
    :raise -> def coerce(%mod{}, _), do: raise(ArgumentError, "The type #{i(mod)} doesn't support coercion")
    :warn -> def coerce(%mod{} = type, _), do: Zodish.Helpers.warn(type, "The type #{i(mod)} doesn't support coercion")
    :ignore -> def coerce(%_{} = type, _), do: type
    value -> raise(ArgumentError, "Invalid option #{i(value)} for config :on_unsupported_coercion, expected :raise, :warn or :ignore")
  end

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

      iex> Z.datetime()
      iex> |> Z.parse(~U[2025-06-27T12:00:00.000Z])
      {:ok, ~U[2025-06-27T12:00:00.000Z]}

  ## Options

  You can use `:coerce` to cast the given value into a DateTime.

      iex> Z.datetime(coerce: true)
      iex> |> Z.parse("2025-06-27T12:00:00.000Z")
      {:ok, ~U[2025-06-27T12:00:00.000Z]}

  You can use `:after` to ensure the given date-time is after a
  certain timestamp.

      iex> Z.datetime(after: ~U[2030-01-01T00:00:00.000Z])
      iex> |> Z.parse(~U[2031-06-27T12:00:00.000Z])
      {:ok, ~U[2031-06-27T12:00:00.000Z]}

      iex> Z.datetime(after: ~U[2030-01-01T00:00:00.000Z])
      iex> |> Z.parse(~U[2025-06-27T12:00:00.000Z])
      {:error, %Zodish.Issue{message: "must be after 2030-01-01 00:00:00.000Z"}}

  Alternatively you can provide an MFA tuple or a function that
  returns a `DateTime`:

      iex> Z.datetime(after: {DateTime, :utc_now, []})
      iex> |> Z.parse(~U[2030-01-01T00:00:00.000Z])
      {:ok, ~U[2030-01-01T00:00:00.000Z]}

      iex> Z.datetime(after: (fn -> DateTime.utc_now() end))
      iex> |> Z.parse(~U[2030-01-01T00:00:00.000Z])
      {:ok, ~U[2030-01-01T00:00:00.000Z]}

  You can also provide a relative time:

      iex> {:ok, _} =
      iex>   Z.datetime(after: {15, :minute, :from_now})
      iex>   |> Z.parse(DateTime.add(DateTime.utc_now(), 16, :minute))

      iex> {:error, _} =
      iex>   Z.datetime(after: {15, :minute, :from_now})
      iex>   |> Z.parse(DateTime.add(DateTime.utc_now(), 14, :minute))

  Likewise, you can use `:before` to ensure the given date-time is
  before the given timestamp.

      iex> {:ok, _} =
      iex>   Z.datetime(before: {15, :minute, :from_now})
      iex>   |> Z.parse(DateTime.add(DateTime.utc_now(), 14, :minute))

      iex> {:error, _} =
      iex>   Z.datetime(before: {15, :minute, :from_now})
      iex>   |> Z.parse(DateTime.add(DateTime.utc_now(), 16, :minute))

  """
  @spec datetime(opts :: [option]) :: TDateTime.t()
        when option:
          {:coerce, boolean()}
          | {:after, DateTime.t()}
          | {:after, mfa()}
          | {:after, (-> DateTime.t())}
          | {:after, {n ::integer(), unit :: :millisecond | :second | :minute | :hour | :day | :week | :month | :year, :from_now}}
          | {:before, DateTime.t()}
          | {:before, mfa()}
          | {:before, (-> DateTime.t())}
          | {:before, {n ::integer(), unit :: :millisecond | :second | :minute | :hour | :day | :week | :month | :year, :from_now}}

  defdelegate datetime(opts \\ []), to: TDateTime, as: :new

    @doc ~S"""
    Defines a decimal type.

        iex> Z.decimal()
        iex> |> Z.parse(Decimal.from_float(3.14))
        {:ok, Decimal.new("3.14")}

    ## Options

    You can use `:gt`, `:gte`, `:lt` and `:lte` to constrain the allowed
    values.

        iex> Z.decimal(gt: Decimal.new("0.0"))
        iex> |> Z.parse(Decimal.new("0.0"))
        {:error, %Zodish.Issue{message: "expected a decimal greater than 0.0, got 0.0"}}

        iex> Z.decimal(gte: Decimal.new("1.0"))
        iex> |> Z.parse(Decimal.new("0.5"))
        {:error, %Zodish.Issue{message: "expected a decimal greater than or equal to 1.0, got 0.5"}}

        iex> Z.decimal(lt: Decimal.new("1.0"))
        iex> |> Z.parse(Decimal.new("1.1"))
        {:error, %Zodish.Issue{message: "expected a decimal less than 1.0, got 1.1"}}

        iex> Z.decimal(lte: Decimal.new("1.0"))
        iex> |> Z.parse(Decimal.new("1.1"))
        {:error, %Zodish.Issue{message: "expected a decimal less than or equal to 1.0, got 1.1"}}

    You can use `:coerce` to cast the given value into a decimal before
    validation.

        iex> Z.decimal(coerce: true)
        iex> |> Z.parse("3.14")
        {:ok, Decimal.new("3.14")}

        iex> Z.decimal(coerce: true)
        iex> |> Z.parse("123")
        {:ok, Decimal.new("123")}

    """
    @spec decimal(opts :: [option]) :: TDateTime.t()
          when option:
                {:coerce, boolean()}
                | {:gt, Decimal.t()}
                | {:gt, Zodish.Option.t(Decimal.t())}
                | {:gte, Decimal.t()}
                | {:gte, Zodish.Option.t(Decimal.t())}
                | {:lt, Decimal.t()}
                | {:lt, Zodish.Option.t(Decimal.t())}
                | {:lte, Decimal.t()}
                | {:lte, Zodish.Option.t(Decimal.t())}

  defdelegate decimal(opts \\ []), to: TDecimal, as: :new

  @doc ~S"""
  Defines an email type (decorated String type).

      iex> Z.email()
      iex> |> Z.parse("foo@bar.com")
      {:ok, "foo@bar.com"}

  ## Options

  You can choose which ruleset to use for validating the email address
  by setting the `:ruleset` option. There are 4 options available:
  - `:gmail` (default) - same rules as Gmail;
  - `:html5` - same rules browsers use to validate `input[type=email]` fields;
  - `:rfc5322` - same rules as the classic emailregex.com (RFC 5322); and
  - `:unicode` - a loose set of rules that allows Unicode (good for intl emails);

        iex> Z.email(ruleset: :gmail)
        iex> |> Z.parse("foo@bar.com")
        {:ok, "foo@bar.com"}

        iex> Z.email(ruleset: :html5)
        iex> |> Z.parse("foo@bar.com")
        {:ok, "foo@bar.com"}

        iex> Z.email(ruleset: :rfc5322)
        iex> |> Z.parse("foo@bar.com")
        {:ok, "foo@bar.com"}

        iex> Z.email(ruleset: :unicode)
        iex> |> Z.parse("foo@bar.com")
        {:ok, "foo@bar.com"}

  ## Errors

  When the given string is empty:

        iex> Z.email()
        iex> |> Z.parse("")
        {:error, %Zodish.Issue{message: "cannot be empty"}}

  When the given string is not a valid email address:

        iex> Z.email()
        iex> |> Z.parse("foo@")
        {:error, %Zodish.Issue{message: "invalid email address"}}

  """
  @spec email(opts :: [option]) :: TEmail.t()
        when option: {:ruleset, :gmail | :html5 | :rfc5322 | :unicode}

  defdelegate email(opts \\ []), to: TEmail, as: :new

  @doc ~S"""
  Defines an enum type (atoms only).

      iex> Z.enum([:foo, :bar])
      iex> |> Z.parse(:foo)
      {:ok, :foo}

  ## Options

  You can use `:coerce` to cast the given value into an atom.

      iex> Z.enum(coerce: true, values: [:foo, :bar])
      iex> |> Z.parse("bar")
      {:ok, :bar}

  ## Errors

  When the given value is not an atom:

      iex> Z.enum([:foo, :bar])
      iex> |> Z.parse("baz")
      {:error, %Zodish.Issue{message: "expected an atom, got string"}}

  When the given value is not an atom but coerce is set to true:

      iex> Z.enum(coerce: true, values: [:foo, :bar])
      iex> |> Z.parse("baz")
      {:error, %Zodish.Issue{message: "is invalid"}}

  """
  @spec enum(values :: [atom(), ...]) :: TEnum.t()
  @spec enum(opts :: [option]) :: TEnum.t()
        when option: {:coerce, boolean()} | {:values, [atom(), ...]}

  defdelegate enum(opts), to: TEnum, as: :new

  @doc ~S"""
  Updates the given type's `:length` option.

      iex> Z.integer()
      iex> |> Z.list(length: 1)
      iex> |> Z.length(2)
      iex> |> Z.parse([1])
      {:error, %Zodish.Issue{message: "expected list to have exactly 2 items, got 1 item"}}

      iex> Z.string(length: 5)
      iex> |> Z.length(1)
      iex> |> Z.parse("Hello")
      {:error, %Zodish.Issue{message: "expected string to have exactly 1 character, got 5 characters"}}

  """
  @spec length(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TList.t()
        when type: TList.t()
  @spec length(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TString.t()
        when type: TString.t()

  def length(type, length, opts \\ [])
  def length(%TList{} = type, length, opts), do: TList.length(type, length, opts)
  def length(%TString{} = type, length, opts), do: TString.length(type, length, opts)

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
      {:error, %Zodish.Issue{message: "expected a float greater than 0.0, got 0.0"}}

      iex> Z.float(gte: 1.0)
      iex> |> Z.parse(0.5)
      {:error, %Zodish.Issue{message: "expected a float greater than or equal to 1.0, got 0.5"}}

      iex> Z.float(lt: 1.0)
      iex> |> Z.parse(1.1)
      {:error, %Zodish.Issue{message: "expected a float less than 1.0, got 1.1"}}

      iex> Z.float(lte: 1.0)
      iex> |> Z.parse(1.1)
      {:error, %Zodish.Issue{message: "expected a float less than or equal to 1.0, got 1.1"}}

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
      {:error, %Zodish.Issue{message: "expected an integer greater than 0, got 0"}}

      iex> Z.integer(gte: 0)
      iex> |> Z.parse(-1)
      {:error, %Zodish.Issue{message: "expected an integer greater than or equal to 0, got -1"}}

      iex> Z.integer(lt: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "expected an integer less than 1, got 2"}}

      iex> Z.integer(lte: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "expected an integer less than or equal to 1, got 2"}}

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
        message: "one or more items of the list did not match the expected type",
        parse_score: 3,
        issues: [%Zodish.Issue{path: ["2"], message: "expected an integer, got string"}]
      }}

  ## Options

  You can use `:length`, `:min` and `:max` to
  constrain the length of the list.

      iex> Z.list(Z.integer(), length: 3)
      iex> |> Z.parse([1, 2, 3, 4])
      {:error, %Zodish.Issue{message: "expected list to have exactly 3 items, got 4 items"}}

      iex> Z.list(Z.integer(), min: 1)
      iex> |> Z.parse([])
      {:error, %Zodish.Issue{message: "expected list to have at least 1 item, got 0 items"}}

      iex> Z.list(Z.integer(), max: 3)
      iex> |> Z.parse([1, 2, 3, 4])
      {:error, %Zodish.Issue{message: "expected list to have at most 3 items, got 4 items"}}

  """
  @spec list(inner_type :: Zodish.Type.t(), opts :: [option]) :: TList.t()
        when option:
               {:length, non_neg_integer()}
               | {:length, Zodish.Option.t(non_neg_integer())}
               | {:min, non_neg_integer()}
               | {:min, Zodish.Option.t(non_neg_integer())}
               | {:max, non_neg_integer()}
               | {:max, Zodish.Option.t(non_neg_integer())}

  defdelegate list(inner_type, opts \\ []), to: TList, as: :new

  @doc ~S"""
  Defines a type that only accepts a specific value.

      iex> Z.literal("foo")
      iex> |> Z.parse("foo")
      {:ok, "foo"}

      iex> Z.literal(42)
      iex> |> Z.parse(51)
      {:error, %Zodish.Issue{message: "expected to be exactly 42, got 51"}}

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
        message: "one or more fields failed validation",
        parse_score: 3,
        issues: [%Zodish.Issue{path: ["email"], message: "unknown field"}]
      }}

  You can also use :coerce to cast values from struct or keyword lists
  to maps before validation:

      iex> Z.coerce(Z.map(:strip, %{name: Z.string(), age: Z.integer(gte: 18)}))
      iex> |> Z.parse(name: "John Doe", email: "johndoe@gmail.com", age: 27)
      {:ok, %{name: "John Doe", age: 27}}

  If you need to validate a map where you don't know what keys will be
  present, then use `Z.record/1` instead.
  """
  @spec map(mode, shape) :: TMap.t()
        when mode: :strip | :strict,
             shape: %{required(atom()) => Zodish.Type.t()}
  @spec map([option, ...], shape) :: TMap.t()
        when option: {:coerce, boolean()} | {:mode, :strip | :strict},
             shape: %{required(atom()) => Zodish.Type.t()}

  defdelegate map(mode_or_opts \\ :strip, shape), to: TMap, as: :new

  @doc ~S"""
  Updates the given type's `:max` option.

      iex> Z.integer()
      iex> |> Z.list(max: 3)
      iex> |> Z.max(2)
      iex> |> Z.parse([1, 2, 3])
      {:error, %Zodish.Issue{message: "expected list to have at most 2 items, got 3 items"}}

      iex> Z.string(max: 3)
      iex> |> Z.max(1)
      iex> |> Z.parse("Foo")
      {:error, %Zodish.Issue{message: "expected string to have at most 1 character, got 3 characters"}}

  """
  @spec max(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TList.t()
        when type: TList.t()
  @spec max(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TString.t()
        when type: TString.t()

  def max(type, length, opts \\ [])
  def max(%TList{} = type, length, opts), do: TList.max(type, length, opts)
  def max(%TString{} = type, length, opts), do: TString.max(type, length, opts)

  @doc ~S"""
  Merges two Map types into one, where `:mode` is inherited from the
  most strict mode between the two given types.

      iex> a = Z.map(:strip, %{name: Z.string()})
      iex> b = Z.map(:strict, %{age: Z.integer()})
      iex>
      iex> Z.merge(a, b)
      iex> |> Z.parse(%{name: "John Doe", age: 27, email: "johndoe@gmail.com"})
      {:error, %Zodish.Issue{
        message: "one or more fields failed validation",
        parse_score: 3,
        issues: [%Zodish.Issue{path: ["email"], message: "unknown field"}]
      }}

      iex> a = Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string()
      iex> })
      iex>
      iex> b = Z.struct(Address, %{
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> })
      iex>
      iex> Z.merge(a, b)
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

  """
  @spec merge(a :: TMap.t(), b :: TMap.t()) :: TMap.t()
  @spec merge(a :: TStruct.t(), b :: TStruct.t()) :: TStruct.t()

  def merge(%TMap{} = a, %TMap{} = b), do: TMap.new(most_strict(a.mode, b.mode), Map.merge(a.shape, b.shape))
  def merge(%TStruct{module: same} = a, %TStruct{module: same} = b) do
    []
    |> Keyword.put(:coerce, a.coerce or b.coerce)
    |> Keyword.put(:mode, most_strict(a.mode, b.mode))
    |> Keyword.put(:module, same)
    |> Keyword.put(:shape, Map.merge(a.shape, b.shape))
    |> TStruct.new()
  end

  @doc ~S"""
  Updates the given type's `:min` option.

      iex> Z.integer()
      iex> |> Z.list(min: 1)
      iex> |> Z.min(2)
      iex> |> Z.parse([1])
      {:error, %Zodish.Issue{message: "expected list to have at least 2 items, got 1 item"}}

      iex> Z.string(min: 1)
      iex> |> Z.min(6)
      iex> |> Z.parse("Foo")
      {:error, %Zodish.Issue{message: "expected string to have at least 6 characters, got 3 characters"}}

  """
  @spec min(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TList.t()
        when type: TList.t()
  @spec min(type, length :: non_neg_integer(), opts :: [{:error, String.t()}]) :: TString.t()
        when type: TString.t()

  def min(type, length, opts \\ [])
  def min(%TList{} = type, length, opts), do: TList.min(type, length, opts)
  def min(%TString{} = type, length, opts), do: TString.min(type, length, opts)

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
      {:error, %Zodish.Issue{message: "expected a number greater than 0, got 0"}}

      iex> Z.number(gte: 0)
      iex> |> Z.parse(-1)
      {:error, %Zodish.Issue{message: "expected a number greater than or equal to 0, got -1"}}

      iex> Z.number(lt: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "expected a number less than 1, got 2"}}

      iex> Z.number(lte: 1)
      iex> |> Z.parse(2)
      {:error, %Zodish.Issue{message: "expected a number less than or equal to 1, got 2"}}

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
  Defines a numeric string type.

      iex> Z.numeric()
      iex> |> Z.parse("123456")
      {:ok, "123456"}

      iex> Z.numeric()
      iex> |> Z.parse("a1b2c3")
      {:error, %Zodish.Issue{message: "must contain numbers only"}}

  This is an alias to `Z.string/1` where it has a regex to match
  numeric strings, therefore it accepts all the same options as
  `Z.string/1` except for the :regex option.
  """
  @spec numeric(opts :: [option]) :: TString.t()
        when option:
               {:coerce, boolean()}
               | {:trim, boolean()}
               | {:downcase, boolean()}
               | {:upcase, boolean()}
               | {:length, non_neg_integer()}
               | {:length, Zodish.Option.t(non_neg_integer())}
               | {:min, non_neg_integer()}
               | {:min, Zodish.Option.t(non_neg_integer())}
               | {:max, non_neg_integer()}
               | {:max, Zodish.Option.t(non_neg_integer())}
               | {:starts_with, String.t()}
               | {:starts_with, Zodish.Option.t(String.t())}
               | {:ends_with, String.t()}
               | {:ends_with, Zodish.Option.t(String.t())}

  @dialyzer {:nowarn_function, numeric: 0, numeric: 1}
  #           ↑ because dialyzer was complaining about the spec having
  #             "too many types for the function"
  def numeric(opts \\ []) do
    {regex, opts} = Keyword.pop(opts, :regex)

    unless is_nil(regex),
      do: raise(ArgumentError, message: "Not allowed to pass a regex to a numeric string type")

    string([
      {:regex, {~r/^[0-9]+$/, error: "must contain numbers only"}}
      | opts
    ])
  end

  @doc ~S"""
  Removes the specified keys from the type's shape.

      iex> Z.map(%{name: Z.string(), age: Z.integer()})
      iex> |> Z.omit([:age])
      iex> |> Z.parse(%{name: "John Doe"})
      {:ok, %{name: "John Doe"}}

      iex> Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> })
      iex> |> Z.omit([:line_1, :line_2])
      iex> |> Z.parse(%{
      iex>   city: "Springfield",
      iex>   state: "IL",
      iex>   zip: "62701"
      iex> })
      {:ok, %Address{
        city: "Springfield",
        state: "IL",
        zip: "62701"
      }}

  """
  @spec omit(type, keys :: [atom()]) :: TMap.t()
        when type: TMap.t()
  @spec omit(type, keys :: [atom()]) :: TStruct.t()
        when type: TStruct.t()

  def omit(%TMap{} = type, keys) when is_list(keys), do: %{type | shape: Map.drop(type.shape, keys)}
  def omit(%TStruct{} = type, keys) when is_list(keys), do: %{type | shape: Map.drop(type.shape, keys)}

  @doc ~S"""
  Makes a given inner type optional, where you can also define a
  default value to be used when the actual value resolves to `nil`.

      iex> Z.integer()
      iex> |> Z.parse(nil)
      {:error, %Zodish.Issue{message: "is required"}}

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
      {:error, %Zodish.Issue{message: "expected an integer, got string"}}

  If you're defining your schema at compile time into a compiled
  variable, then you won't be able to use an anonymous function as the
  default value. So instead you can pass an mfa tuple of the function
  that should be called to get the default value:

      iex> Z.optional(Z.integer(), default: {Echo, :say, [42]})
      iex> |> Z.parse(nil)
      {:ok, 42}

  """
  @spec optional(inner_type :: Zodish.Type.t(), opts :: [option]) :: TOptional.t()
        when option: {:default, (-> any()) | any() | nil}

  defdelegate optional(inner_type, opts \\ []), to: TOptional, as: :new

  @doc ~S"""
  Checks whether the given type is an optional type.

      iex> Z.string()
      iex> |> Z.optional()
      iex> |> Z.optional?()
      true

      iex> Z.string()
      iex> |> Z.optional?()
      false

  It also works if the type is wrapped in refinements and/or
  transformations:

      iex> Z.string()
      iex> |> Z.optional()
      iex> |> Z.refine(fn _ -> true end)
      iex> |> Z.refine(fn _ -> true end)
      iex> |> Z.transform(fn value -> value end)
      iex> |> Z.optional?()
      true

  """
  @spec optional?(type :: Zodish.Type.t()) :: boolean()

  def optional?(%TOptional{}), do: true
  def optional?(%Refine{inner_type: %_{} = inner_type}), do: optional?(inner_type)
  def optional?(%Transform{inner_type: %_{} = inner_type}), do: optional?(inner_type)
  def optional?(_), do: false

  @doc ~S"""
  Keeps only the specified keys from the type's shape.

      iex> Z.map(%{name: Z.string(), age: Z.integer()})
      iex> |> Z.pick([:name])
      iex> |> Z.parse(%{name: "John Doe"})
      {:ok, %{name: "John Doe"}}

      iex> Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> })
      iex> |> Z.pick([:city, :state, :zip])
      iex> |> Z.parse(%{
      iex>   city: "Springfield",
      iex>   state: "IL",
      iex>   zip: "62701"
      iex> })
      {:ok, %Address{
        city: "Springfield",
        state: "IL",
        zip: "62701"
      }}

  """
  @spec pick(type, keys :: [atom()]) :: TMap.t()
        when type: TMap.t()
  @spec pick(type, keys :: [atom()]) :: TStruct.t()
        when type: TStruct.t()

  def pick(%TMap{} = type, keys) when is_list(keys), do: %{type | shape: Map.take(type.shape, keys)}
  def pick(%TStruct{} = type, keys) when is_list(keys), do: %{type | shape: Map.take(type.shape, keys)}

  @doc ~S"""
  Defines a record type.

      iex> Z.record()
      iex> |> Z.parse(%{"foo" => "bar"})
      {:ok, %{"foo" => "bar"}}

  ## Options

  You can use the option `:keys` to default a schema for the keys in
  the record.

      iex> Z.record(keys: Z.string(min: 1))
      iex> |> Z.parse(%{foo: "bar"})
      {:error, %Zodish.Issue{
        path: [],
        message: "one or more fields failed validation",
        parse_score: 1,
        issues: [%Zodish.Issue{path: ["foo"], message: "expected a string, got atom"}]
      }}

  Although you can specify a schema for the keys, it must be a string
  type.

      iex> Z.record(keys: Z.integer())
      ** (ArgumentError) Record keys must be string

  You can use the option `:values` to set a schema that will be used
  to parse the values in the record.

      iex> Z.record(values: Z.string(min: 1))
      iex> |> Z.parse(%{"foo" => ""})
      {:error, %Zodish.Issue{
        path: [],
        message: "one or more fields failed validation",
        parse_score: 1,
        issues: [%Zodish.Issue{path: ["foo"], message: "expected string to have at least 1 character, got 0 characters"}],
      }}

  Alternatively you can pass a type as single argument to `Z.record/1`
  where it will be used as the :values types:

      iex> Z.record(Z.string(min: 1))
      iex> |> Z.parse(%{"foo" => ""})
      {:error, %Zodish.Issue{
        path: [],
        message: "one or more fields failed validation",
        parse_score: 1,
        issues: [%Zodish.Issue{path: ["foo"], message: "expected string to have at least 1 character, got 0 characters"}],
      }}

  """
  @spec record(opts :: [option]) :: TRecord.t()
        when option:
               {:keys, Zodish.Type.t()}
               | {:values, Zodish.Type.t()}

  def record(opts \\ [])

  def record(%_{} = type), do: TRecord.new(values: type)
  def record(opts), do: TRecord.new(opts)

  @doc ~S"""
  Refines a value with a custom validation.

      iex> is_even = fn x -> rem(x, 2) == 0 end
      iex>
      iex> Z.integer()
      iex> |> Z.refine(is_even)
      iex> |> Z.parse(3)
      {:error, %Zodish.Issue{message: "is invalid", parse_score: 1}}

  ## Options

  You can use the options `:error` to set a custom error message that
  will be used when the validation fails.

      iex> is_even = fn x -> rem(x, 2) == 0 end
      iex>
      iex> Z.integer()
      iex> |> Z.refine(is_even, error: "must be even")
      iex> |> Z.parse(3)
      {:error, %Zodish.Issue{message: "must be even", parse_score: 1}}

  """
  @spec refine(inner_type, fun, opts :: [option]) :: Refine.t()
        when inner_type: Zodish.Type.t(),
             fun: (any() -> boolean()) | mfa(),
             option: {:error, String.t()}

  defdelegate refine(inner_type, fun, opts \\ []), to: Refine, as: :new

  @doc ~S"""
  Switches the mode of the given schema to :strict, where additional
  fields are not allowed.

      iex> Z.strict(Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> }))
      iex> |> Z.parse(%{
      iex>   name: "John Doe",
      iex>   line_1: "123 Main St",
      iex>   line_2: "Apt 4B",
      iex>   city: "Springfield",
      iex>   state: "IL",
      iex>   zip: "62701"
      iex> })
      {:error, %Zodish.Issue{
        message: "one or more fields failed validation",
        parse_score: 6,
        issues: [%Zodish.Issue{path: ["name"], message: "unknown field"}]
      }}

  Worth noting that :strict is the default mode for `Z.struct/2`.
  """
  @spec strict(Zodish.Type.Map.t()) :: Zodish.Type.Map.t()
  @spec strict(Zodish.Type.Struct.t()) :: Zodish.Type.Struct.t()

  def strict(%TMap{} = type), do: TMap.strict(type)
  def strict(%TStruct{} = type), do: TStruct.strict(type)

  @doc ~S"""
  Defines a string type.

      iex> Z.string()
      iex> |> Z.parse("Hello, World!")
      {:ok, "Hello, World!"}

  ## Options

  You can use `:length`, `:min` and `:max` to
  constrain the length of the string.

      iex> Z.string(length: 3)
      iex> |> Z.parse("foobar")
      {:error, %Zodish.Issue{message: "expected string to have exactly 3 characters, got 6 characters"}}

      iex> Z.string(min: 1)
      iex> |> Z.parse("")
      {:error, %Zodish.Issue{message: "expected string to have at least 1 character, got 0 characters"}}

      iex> Z.string(max: 3)
      iex> |> Z.parse("foobar")
      {:error, %Zodish.Issue{message: "expected string to have at most 3 characters, got 6 characters"}}

  You can also use `:trim` to trim leading and trailing whitespaces
  from the string before validation.

      iex> Z.string(trim: true, min: 1)
      iex> |> Z.parse("   ")
      {:error, %Zodish.Issue{message: "expected string to have at least 1 character, got 0 characters"}}

  You can use `:starts_with` and `:ends_with` to check if the string
  starts with a given prefix or ends with a given suffix.

      iex> Z.string(starts_with: "sk_")
      iex> |> Z.parse("pk_123")
      {:error, %Zodish.Issue{message: "expected string to start with \"sk_\", got \"pk_123\""}}

      iex> Z.string(ends_with: "bar")
      iex> |> Z.parse("fizzbuzz")
      {:error, %Zodish.Issue{message: "expected string to end with \"bar\", got \"fizzbuzz\""}}

  You can use `:regex` to validate the string against a regular
  expression.

      iex> Z.string(regex: ~r/^\d+$/)
      iex> |> Z.parse("123abc")
      {:error, %Zodish.Issue{message: "expected string to match /^\\d+$/, got \"123abc\""}}

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
               | {:length, non_neg_integer()}
               | {:length, Zodish.Option.t(non_neg_integer())}
               | {:min, non_neg_integer()}
               | {:min, Zodish.Option.t(non_neg_integer())}
               | {:max, non_neg_integer()}
               | {:max, Zodish.Option.t(non_neg_integer())}
               | {:starts_with, String.t()}
               | {:starts_with, Zodish.Option.t(String.t())}
               | {:ends_with, String.t()}
               | {:ends_with, Zodish.Option.t(String.t())}
               | {:regex, Regex.t()}
               | {:regex, Zodish.Option.t(Regex.t())}

  defdelegate string(opts \\ []), to: TString, as: :new

  @doc ~S"""
  Switches the mode of the given schema to :strip, where additional
  fields are ignored.

      iex> Z.strip(Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> }))
      iex> |> Z.parse(%{
      iex>   name: "John Doe",
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

  Worth noting that :strip is the default mode for `Z.map/1`.
  """
  @spec strip(Zodish.Type.Map.t()) :: Zodish.Type.Map.t()
  @spec strip(Zodish.Type.Struct.t()) :: Zodish.Type.Struct.t()

  def strip(%TMap{} = type), do: TMap.strip(type)
  def strip(%TStruct{} = type), do: TStruct.strip(type)

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

  If your Zodish schema includes a key that doesn't exist in the
  struct, then an `ArgumentError` will be raised.

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
        message: "one or more fields failed validation",
        parse_score: 6,
        issues: [%Zodish.Issue{path: ["name"], message: "unknown field"}]
      }}

  In `Zodish.struct/2` the schema is :strict by default, meaning that
  additional fields are not allowed. If you want it to behave as
  :strip, like it's available to `Zodish.map/2`, you can use on of the
  following options:

  **Option 1**:

      iex> Z.struct([module: Address, mode: :strip], %{
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
      {:ok, %Address{
        line_1: "123 Main St",
        line_2: "Apt 4B",
        city: "Springfield",
        state: "IL",
        zip: "62701"
      }}

  **Option 2**:

      iex> Z.strip(Z.struct(Address, %{
      iex>   line_1: Z.string(),
      iex>   line_2: Z.string(),
      iex>   city: Z.string(),
      iex>   state: Z.string(),
      iex>   zip: Z.string(),
      iex> }))
      iex> |> Z.parse(%{
      iex>   name: "John Doe",
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

  """
  @spec struct(mod, shape) :: TStruct.t()
        when mod: module,
             shape: %{required(atom()) => Zodish.Type.t()}
  @spec struct([option, ...], shape) :: TStruct.t()
        when option: {:module, module} | {:mode, :strict | :strip},
             shape: %{required(atom()) => Zodish.Type.t()}

  defdelegate struct(mod_or_opts, shape), to: TStruct, as: :new

  @doc ~S"""
  Transforms the parsed value using a given function.

      iex> Z.integer()
      iex> |> Z.transform(fn x -> x * 2 end)
      iex> |> Z.parse(3)
      {:ok, 6}

  Alternatively, a `{mod, fun, args}` tuple can be provided indicating
  what function should be invoked. The function is invoked with the
  Zodish value as its first argument followed by the `args` you
  provided.

      iex> Z.integer()
      iex> |> Z.transform({Integer, :to_string, []})
      iex> |> Z.parse(10)
      {:ok, "10"}

  """
  @spec transform(inner_type, fun) :: Transform.t()
        when inner_type: Zodish.Type.t(),
             fun: (any() -> any())

  defdelegate transform(inner_type, fun), to: Transform, as: :new

  @doc ~S"""
  Defines a tuple type.

      iex> Z.tuple([Z.atom(), Z.integer()])
      iex> |> Z.parse({:ok, 123})
      {:ok, {:ok, 123}}

      iex> Z.tuple([Z.atom(), Z.integer(), Z.string()])
      iex> |> Z.parse({:ok, "abc"})
      {:error, %Zodish.Issue{message: "expected a tuple of length 3, got length 2"}}

      iex> Z.tuple([Z.atom(), Z.integer()])
      iex> |> Z.parse({:ok, "abc"})
      {:error, %Zodish.Issue{
        message: "one or more elements of the tuple did not match the expected type",
        parse_score: 1,
        issues: [%Zodish.Issue{path: ["1"], message: "expected an integer, got string"}],
      }}

  """
  @spec tuple(elements :: [Zodish.Type.t(), ...]) :: TTuple.t()

  defdelegate tuple(elements), to: TTuple, as: :new

  @doc ~S"""
  Defines a union type of 2 or more schemas.

      iex> Z.union([
      iex>   Z.string(),
      iex>   Z.integer()
      iex> ])
      iex> |> Z.parse("Hello, World!")
      {:ok, "Hello, World!"}

      iex> Z.union([
      iex>   Z.string(),
      iex>   Z.integer()
      iex> ])
      iex> |> Z.parse(23.45)
      {:error, %Zodish.Issue{message: "expected an integer, got float"}}

  The resulting error will be from the schema which made the most
  progress parsing the value.

      iex> a = Z.map(%{foo: Z.string(), bar: Z.integer(), baz: Z.boolean()})
      iex> b = Z.map(%{foo: Z.string(), qux: Z.float()})
      iex>
      iex> Z.union([a, b])
      iex> |> Z.parse(%{foo: "Hello", bar: 123})
      {:error, %Zodish.Issue{message: "one or more fields failed validation", parse_score: 3, issues: [
        %Zodish.Issue{path: ["baz"], message: "is required"}
      ]}}

  > #### Warning {: .warning}
  >
  > The logic for selecting the best schema validation issues is still
  > a work in progress and may be changed in the future.

  """
  @spec union(inner_types) :: TUnion.t()
        when inner_types: [Zodish.Type.t(), ...]

  defdelegate union(schemas), to: TUnion, as: :new

  @doc ~S"""
  Defines a string URI type.

      iex> Z.uri()
      iex> |> Z.parse("https://foo.bar/")
      {:ok, "https://foo.bar/"}

  ## Options

  You can constrain which schemes are allowed by passing the
  `:schemes` option:

      iex> Z.uri(schemes: ["https"])
      iex> |> Z.parse("http://localhost/")
      {:error, %Zodish.Issue{message: "scheme not allowed"}}

  You can trim the trailing slash in the uri by passing the
  `:trailing_slash` option:

      iex> Z.uri(trailing_slash: :trim)
      iex> |> Z.parse("https://foo.bar/api/")
      {:ok, "https://foo.bar/api"}

  Likewise, you can enfore the trailing slash:

      iex> Z.uri(trailing_slash: :enforce)
      iex> |> Z.parse("https://foo.bar/api")
      {:ok, "https://foo.bar/api/"}

  """
  @spec uri([option]) :: TUri.t()
        when option:
          {:schemes, [String.t()]}
          | {:trailing_slash, :keep | :trim | :enforce}

  defdelegate uri(opts \\ []), to: TUri, as: :new

  @doc ~S"""
  Defines a UUID type (decorated String type).

      iex> Z.uuid()
      iex> |> Z.parse("550e8400-e29b-41d4-a716-446655440000")
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}

  You can optionally specify which version of UUID to validate for.

      iex> Z.uuid(:any)
      iex> |> Z.parse("550e8400-e29b-41d4-a716-446655440000")
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}

      iex> Z.uuid(:v4)
      iex> |> Z.parse("67ef5479-e5c2-411f-9cfc-82ff3c17a76e")
      {:ok, "67ef5479-e5c2-411f-9cfc-82ff3c17a76e"}

      iex> Z.uuid(:v7)
      iex> |> Z.parse("019798df-04e0-7279-8bca-26f70bb361d2")
      {:ok, "019798df-04e0-7279-8bca-26f70bb361d2"}

  There are 9 supported options: `:any` (default), `:v1`, `:v2`, `:v3`,
  `:v4`, `:v5`, `:v6`, `:v7` and `:v8`.
  """
  defdelegate uuid(version \\ :any), to: TUuid, as: :new

  #
  #   PRIVATE
  #

  defp most_strict(:strict, _), do: :strict
  defp most_strict(_, :strict), do: :strict
  defp most_strict(:strip, :strip), do: :strip
end
