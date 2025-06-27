defmodule Zodish.Type.Integer do
  @moduledoc ~S"""
  This module describes a Zodish integer type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TInteger

  @type t() :: %TInteger{
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

  def new(opts \\ []) do
    Enum.reduce(opts, %TInteger{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:gt, {value, opts}}, type -> gt(type, value, opts)
      {:gt, value}, type -> gt(type, value)
      {:gte, {value, opts}}, type -> gte(type, value, opts)
      {:gte, value}, type -> gte(type, value)
      {:lt, {value, opts}}, type -> lt(type, value, opts)
      {:lt, value}, type -> lt(type, value)
      {:lte, {value, opts}}, type -> lte(type, value, opts)
      {:lte, value}, type -> lte(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.Integer")
    end)
  end

  def coerce(%TInteger{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  @opts [error: "Expected a integer greater than {{gt}}, got {{value}}"]
  def gt(%TInteger{} = type, value, opts \\ [])
      when is_integer(value),
      do: %{type | gt: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected a integer greater than or equal to {{gte}}, got {{value}}"]
  def gte(%TInteger{} = type, value, opts \\ [])
      when is_integer(value),
      do: %{type | gte: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected a integer less than {{lt}}, got {{value}}"]
  def lt(%TInteger{} = type, value, opts \\ [])
      when is_integer(value),
      do: %{type | lt: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected a integer less than or equal to {{lte}}, got {{value}}"]
  def lte(%TInteger{} = type, value, opts \\ [])
      when is_integer(value),
      do: %{type | lte: {value, merge_opts(@opts, opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.Integer do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.Integer, as: TInteger

  @impl Zodish.Type
  def parse(%TInteger{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         :ok <- validate_gt(type, value),
         :ok <- validate_gte(type, value),
         :ok <- validate_lt(type, value),
         :ok <- validate_lte(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("Is required")}
  defp validate_required(_), do: :ok

  defp parse_integer_string(value) do
    {:ok, String.to_integer(value)}
  rescue
    _ -> {:error, "invalid"}
  end

  defp parse_float_string(value) do
    {:ok, trunc(String.to_float(value))}
  rescue
    _ -> {:error, "invalid"}
  end

  defp coerce(%{coerce: true}, value) when is_float(value), do: {:ok, trunc(value)}
  defp coerce(%{coerce: true}, <<value::binary>>) do
    with {:error, _} <- parse_integer_string(value),
         {:error, _} <- parse_float_string(value),
         do: {:error, issue("Cannot coerce #{inspect(value)} to integer")}
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_integer(value), do: :ok
  defp validate_type(value), do: {:error, issue("Expected a integer, got #{typeof(value)}")}

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
