defmodule Zodish.Type.DateTime do
  @moduledoc ~S"""
  This module describes a Zodish date-time type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TDateTime

  @type unit() :: :millisecond | :second | :minute | :hour | :day | :week | :month | :year
  @units [:millisecond, :second, :minute, :hour, :day, :week, :month, :year]

  @type t() :: %TDateTime{
          coerce: boolean(),
          after: Zodish.Option.t(DateTime.t() | {n :: integer(), unit(), :from_now} | mfa() | (-> DateTime.t())) | nil,
          before: Zodish.Option.t(DateTime.t() | {n :: integer(), unit(), :from_now} | mfa() | (-> DateTime.t())) | nil
        }

  defstruct coerce: false,
            after: nil,
            before: nil

  @doc ~S"""
  Creates a new DateTime type.
  """
  def new(opts \\ []) do
    Enum.reduce(opts, %TDateTime{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:after, value}, type -> is_after(type, value)
      {:before, value}, type -> is_before(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.DateTime")
    end)
  end

  @doc false
  def coerce(%TDateTime{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  @doc false
  def is_after(type, value, opts \\ [])
  def is_after(%TDateTime{} = type, nil, _), do: %{type | after: nil}
  def is_after(%TDateTime{} = type, %DateTime{} = dt, opts),
    do: %{type | after: {dt, merge_opts([error: "must be after {{after}}"], opts)}}
  def is_after(%TDateTime{} = type, {n, unit, :from_now}, opts)
      when is_integer(n) and unit in @units,
      do: %{type | after: {{n, unit, :from_now}, merge_opts([error: "must be after {{n | #{unit}}} from now"], opts)}}
  def is_after(%TDateTime{} = type, {m, f, a} = mfa, opts)
      when is_atom(m) and is_atom(f) and is_list(a),
      do: %{type | after: {mfa, merge_opts([error: "must be after {{after}}"], opts)}}
  def is_after(%TDateTime{} = type, fun, opts)
      when is_function(fun, 0),
      do: %{type | after: {fun, merge_opts([error: "must be after {{after}}"], opts)}}

  @doc false
  def is_before(type, value, opts \\ [])
  def is_before(%TDateTime{} = type, nil, _), do: %{type | before: nil}
  def is_before(%TDateTime{} = type, %DateTime{} = dt, opts),
    do: %{type | before: {dt, merge_opts([error: "must be before {{before}}"], opts)}}
  def is_before(%TDateTime{} = type, {n, unit, :from_now}, opts)
      when is_integer(n) and unit in @units,
      do: %{type | before: {{n, unit, :from_now}, merge_opts([error: "must be before {{n | #{unit}}} from now"], opts)}}
  def is_before(%TDateTime{} = type, {m, f, a} = mfa, opts)
      when is_atom(m) and is_atom(f) and is_list(a),
      do: %{type | before: {mfa, merge_opts([error: "must be before {{before}}"], opts)}}
  def is_before(%TDateTime{} = type, fun, opts)
    when is_function(fun, 0),
    do: %{type | before: {fun, merge_opts([error: "must be before {{before}}"], opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.DateTime do
  import DateTime, only: [add: 3, utc_now: 0]
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.DateTime, as: TDateTime

  @impl Zodish.Type
  def parse(%TDateTime{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         :ok <- validate_after(type, value),
         :ok <- validate_before(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp coerce(%{coerce: true}, <<value::binary>>) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> {:ok, datetime}
      {:error, _} -> {:error, issue("expected a valid ISO8601 date-time string, got #{inspect(value)}")}
    end
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(%DateTime{}), do: :ok
  defp validate_type(value), do: {:error, issue("expected a DateTime, got #{typeof(value)}")}

  defp dt!(%DateTime{} = dt), do: dt

  # returns {datetime, ctx map}
  defp resolve(%DateTime{} = dt), do: {dt, %{}}
  defp resolve({n, unit, :from_now}), do: {dt!(add(utc_now(), n, unit)), %{n: n, unit: unit}}
  defp resolve({m, f, a}), do: {dt!(apply(m, f, a)), %{}}
  defp resolve(fun) when is_function(fun, 0), do: {dt!(apply(fun, [])), %{}}

  defp validate_after(%{after: nil}, _), do: :ok
  defp validate_after(%{after: {b, opts}}, a) do
    {b, ctx} = resolve(b)
    ctx = Map.put(ctx, :after, b)

    case DateTime.compare(a, b) do
      :lt -> {:error, issue(opts.error, ctx)}
      _ -> :ok
    end
  end

  defp validate_before(%{before: nil}, _), do: :ok
  defp validate_before(%{before: {b, opts}}, a) do
    {b, ctx} = resolve(b)
    ctx = Map.put(ctx, :before, b)

    case DateTime.compare(a, b) do
      :gt -> {:error, issue(opts.error, ctx)}
      _ -> :ok
    end
  end
end
