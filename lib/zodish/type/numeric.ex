defmodule Zodish.Type.Numeric do
  @moduledoc ~S"""
  This module describes a Zodish numeric type (string).
  """

  import Kernel, except: [min: 2, max: 2]
  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TNumeric

  @type t() :: %TNumeric{
          length: Zodish.Option.t(non_neg_integer()) | nil,
          min: Zodish.Option.t(non_neg_integer()) | nil,
          max: Zodish.Option.t(non_neg_integer()) | nil
        }

  defstruct length: nil,
            min: nil,
            max: nil

  @doc ~S"""
  Creates a new Numeric type.
  """
  def new(opts \\ []) do
    Enum.reduce(opts, %TNumeric{}, fn
      {:length, {value, opts}}, type -> length(type, value, opts)
      {:length, value}, type -> length(type, value)
      {:min, {value, opts}}, type -> min(type, value, opts)
      {:min, value}, type -> min(type, value)
      {:max, {value, opts}}, type -> max(type, value, opts)
      {:max, value}, type -> max(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Numeric")
    end)
  end

  @opts [error: "expected numeric string to have exactly {{length | digit}}, got {{actual_length | digit}}"]
  def length(%TNumeric{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | length: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected numeric string to have at least {{min | digit}}, got {{actual_length | digit}}"]
  def min(%TNumeric{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | min: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected numeric string to have at most {{max | digit}}, got {{actual_length | digit}}"]
  def max(%TNumeric{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | max: {value, merge_opts(@opts, opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.Numeric do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.Numeric, as: TNumeric

  @impl Zodish.Type
  def parse(%TNumeric{} = type, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(value),
         :ok <- validate_numeric(value),
         :ok <- validate_length(type, value),
         :ok <- validate_min(type, value),
         :ok <- validate_max(type, value),
         do: {:ok, value}
  end

  @impl Zodish.Type
  def to_spec(%TNumeric{}), do: quote(do: String.t())

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp validate_type(<<_::binary>>), do: :ok
  defp validate_type(value), do: {:error, issue("expected a numeric string, got #{typeof(value)}")}

  @compile {:inline, regex: 1}
  defp regex(:base10), do: ~r/^[0-9]+$/

  defp validate_numeric(value) do
    case String.match?(value, regex(:base10)) do
      true -> :ok
      false -> {:error, issue("must contain 0-9 digits only")}
    end
  end

  defp validate_length(%{length: nil}, _), do: :ok
  defp validate_length(%{length: {length, opts}}, value) do
    actual_length = String.length(value)

    case actual_length == length do
      true -> :ok
      false -> {:error, issue(opts.error, %{length: length, actual_length: actual_length})}
    end
  end

  defp validate_min(%{min: nil}, _), do: :ok
  defp validate_min(%{min: {min, opts}}, value) do
    actual_length = String.length(value)

    case actual_length >= min do
      true -> :ok
      false -> {:error, issue(opts.error, %{min: min, actual_length: actual_length})}
    end
  end

  defp validate_max(%{max: nil}, _), do: :ok
  defp validate_max(%{max: {max, opts}}, value) do
    actual_length = String.length(value)

    case actual_length <= max do
      true -> :ok
      false -> {:error, issue(opts.error, %{max: max, actual_length: actual_length})}
    end
  end
end
