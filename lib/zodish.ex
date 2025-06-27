defmodule Zodish do
  @moduledoc ~S"""
  Zodish is a schema parser and validator library heavily inspired by
  JavaScript's Zod.
  """

  alias Zodish.Type.String, as: TString

  @doc ~S"""
  Parses a value based on the given type.

      iex> Z.string()
      iex> |> Z.parse("Hello, World!")
      {:ok, "Hello, World!"}

  """
  defdelegate parse(type, value), to: Zodish.Parseable

  @doc ~S"""
  Defines a new string type.

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
  defdelegate string(opts \\ []), to: TString, as: :new
end
