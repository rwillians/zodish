defmodule Zodish.Type.Number do
  @moduledoc ~S"""
  This module describes a Zodish number type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TNumber

  @type t() :: %TNumber{
          coerce: boolean(),
          gt: Zodish.Option.t(integer()) | nil,
          gte: Zodish.Option.t(integer()) | nil,
          lt: Zodish.Option.t(integer()) | nil,
          lte: Zodish.Option.t(integer()) | nil
        }

  defstruct coerce: false,
            gt: nil,
            gte: nil,
            lt: nil,
            lte: nil

  @doc ~S"""
  Creates a new Number type.
  """
  def new(opts \\ []) do
    Enum.reduce(opts, %TNumber{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:gt, {value, opts}}, type -> gt(type, value, opts)
      {:gt, value}, type -> gt(type, value)
      {:gte, {value, opts}}, type -> gte(type, value, opts)
      {:gte, value}, type -> gte(type, value)
      {:lt, {value, opts}}, type -> lt(type, value, opts)
      {:lt, value}, type -> lt(type, value)
      {:lte, {value, opts}}, type -> lte(type, value, opts)
      {:lte, value}, type -> lte(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.Number")
    end)
  end

  @doc ~S"""
  Either enables or disables coercion for the given Number type.
  """
  def coerce(%TNumber{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  @opts [error: "expected a number greater than {{gt}}, got {{value}}"]
  def gt(%TNumber{} = type, value, opts \\ [])
      when is_number(value),
      do: %{type | gt: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected a number greater than or equal to {{gte}}, got {{value}}"]
  def gte(%TNumber{} = type, value, opts \\ [])
      when is_number(value),
      do: %{type | gte: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected a number less than {{lt}}, got {{value}}"]
  def lt(%TNumber{} = type, value, opts \\ [])
      when is_number(value),
      do: %{type | lt: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected a number less than or equal to {{lte}}, got {{value}}"]
  def lte(%TNumber{} = type, value, opts \\ [])
      when is_number(value),
      do: %{type | lte: {value, merge_opts(@opts, opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.Number do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.Number, as: TNumber

  @impl Zodish.Type
  def parse(%TNumber{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         :ok <- validate_gt(type, value),
         :ok <- validate_gte(type, value),
         :ok <- validate_lt(type, value),
         :ok <- validate_lte(type, value),
         do: {:ok, value}
  end

  @impl Zodish.Type
  def to_spec(%TNumber{}), do: quote(do: number())

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp parse_integer_string(value) do
    {:ok, String.to_integer(value)}
  rescue
    _ -> {:error, "invalid"}
  end

  defp parse_float_string(value) do
    {:ok, String.to_float(value)}
  rescue
    _ -> {:error, "invalid"}
  end

  defp coerce(%{coerce: true}, <<value::binary>>) do
    with {:error, _} <- parse_integer_string(value),
         {:error, _} <- parse_float_string(value),
         do: {:error, issue("cannot coerce #{inspect(value)} to a number")}
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_number(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected a number, got #{typeof(value)}")}

  defp validate_gt(%{gt: nil}, _), do: :ok
  defp validate_gt(%{gt: {gt, opts}}, value) do
    case value > gt do
      true -> :ok
      false -> {:error, issue(opts.error, %{gt: gt, value: value})}
    end
  end

  defp validate_gte(%{gte: nil}, _), do: :ok
  defp validate_gte(%{gte: {gte, opts}}, value) do
    case value >= gte do
      true -> :ok
      false -> {:error, issue(opts.error, %{gte: gte, value: value})}
    end
  end

  defp validate_lt(%{lt: nil}, _), do: :ok
  defp validate_lt(%{lt: {lt, opts}}, value) do
    case value < lt do
      true -> :ok
      false -> {:error, issue(opts.error, %{lt: lt, value: value})}
    end
  end

  defp validate_lte(%{lte: nil}, _), do: :ok
  defp validate_lte(%{lte: {lte, opts}}, value) do
    case value <= lte do
      true -> :ok
      false -> {:error, issue(opts.error, %{lte: lte, value: value})}
    end
  end
end
