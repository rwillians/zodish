defmodule Zodish.Type.Decimal do
  @moduledoc ~S"""
  This module describes a Zodish float type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TDecimal

  @type t() :: %TDecimal{
          coerce: boolean(),
          gt: Zodish.Option.t(Decimal.t()) | nil,
          gte: Zodish.Option.t(Decimal.t()) | nil,
          lt: Zodish.Option.t(Decimal.t()) | nil,
          lte: Zodish.Option.t(Decimal.t()) | nil
        }

  defstruct coerce: false,
            gt: nil,
            gte: nil,
            lt: nil,
            lte: nil

  @doc false
  def new(opts \\ []) do
    Enum.reduce(opts, %TDecimal{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:gt, {value, opts}}, type -> gt(type, value, opts)
      {:gt, value}, type -> gt(type, value)
      {:gte, {value, opts}}, type -> gte(type, value, opts)
      {:gte, value}, type -> gte(type, value)
      {:lt, {value, opts}}, type -> lt(type, value, opts)
      {:lt, value}, type -> lt(type, value)
      {:lte, {value, opts}}, type -> lte(type, value, opts)
      {:lte, value}, type -> lte(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.Decimal")
    end)
  end

  @doc false
  def coerce(%TDecimal{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  @doc false
  @opts [error: "expected a decimal greater than {{gt}}, got {{value}}"]
  def gt(type, value, opts \\ [])
  def gt(%TDecimal{} = type, %Decimal{} = value, opts),
    do: %{type | gt: {value, merge_opts(@opts, opts)}}
  def gt(%TDecimal{} = type, value, opts)
      when is_float(value),
      do: gt(type, Decimal.from_float(value), opts)
  def gt(%TDecimal{} = type, value, opts)
      when is_integer(value),
      do: gt(type, Decimal.new("#{value}"), opts)

  @doc false
  @opts [error: "expected a decimal greater than or equal to {{gte}}, got {{value}}"]
  def gte(type, value, opts \\ [])
  def gte(%TDecimal{} = type, %Decimal{} = value, opts),
    do: %{type | gte: {value, merge_opts(@opts, opts)}}
  def gte(%TDecimal{} = type, value, opts)
      when is_float(value),
      do: gte(type, Decimal.from_float(value), opts)
  def gte(%TDecimal{} = type, value, opts)
      when is_integer(value),
      do: gte(type, Decimal.new("#{value}"), opts)

  @doc false
  @opts [error: "expected a decimal less than {{lt}}, got {{value}}"]
  def lt(type, value, opts \\ [])
  def lt(%TDecimal{} = type, %Decimal{} = value, opts),
    do: %{type | lt: {value, merge_opts(@opts, opts)}}
  def lt(%TDecimal{} = type, value, opts)
      when is_float(value),
      do: lt(type, Decimal.from_float(value), opts)
  def lt(%TDecimal{} = type, value, opts)
      when is_integer(value),
      do: lt(type, Decimal.new("#{value}"), opts)

  @doc false
  @opts [error: "expected a decimal less than or equal to {{lte}}, got {{value}}"]
  def lte(type, value, opts \\ [])
  def lte(%TDecimal{} = type, %Decimal{} = value, opts),
    do: %{type | lte: {value, merge_opts(@opts, opts)}}
  def lte(%TDecimal{} = type, value, opts)
      when is_float(value),
      do: lte(type, Decimal.from_float(value), opts)
  def lte(%TDecimal{} = type, value, opts)
      when is_integer(value),
      do: lte(type, Decimal.new("#{value}"), opts)
end

defimpl Zodish.Type, for: Zodish.Type.Decimal do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.Decimal, as: TDecimal

  @impl Zodish.Type
  def parse(%TDecimal{} = type, value) do
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

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp coerce(_, %Decimal{} = value), do: {:ok, value}
  defp coerce(%{coerce: true}, value) when is_float(value), do: {:ok, Decimal.from_float(value)}
  defp coerce(%{coerce: true}, value) when is_integer(value), do: {:ok, Decimal.new("#{value}")}
  defp coerce(%{coerce: true}, <<value::binary>>) do
    case Decimal.parse(value) do
      {%Decimal{} = decimal, ""} -> {:ok, decimal}
      _ -> {:error, issue("cannot coerce #{inspect(value)} into a decimal")}
    end
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(%Decimal{}), do: :ok
  defp validate_type(value), do: {:error, issue("expected a decimal, got #{typeof(value)}")}

  defp validate_gt(%{gt: nil}, _), do: :ok
  defp validate_gt(%{gt: {%Decimal{} = gt, opts}}, %Decimal{} = value) do
    case Decimal.gt?(value, gt) do
      true -> :ok
      false -> {:error, issue(opts.error, %{gt: gt, value: value})}
    end
  end

  defp validate_gte(%{gte: nil}, _), do: :ok
  defp validate_gte(%{gte: {%Decimal{} = gte, opts}}, %Decimal{} = value) do
    case Decimal.gte?(value, gte) do
      true -> :ok
      false -> {:error, issue(opts.error, %{gte: gte, value: value})}
    end
  end

  defp validate_lt(%{lt: nil}, _), do: :ok
  defp validate_lt(%{lt: {%Decimal{} = lt, opts}}, %Decimal{} = value) do
    case Decimal.lt?(value, lt) do
      true -> :ok
      false -> {:error, issue(opts.error, %{lt: lt, value: value})}
    end
  end

  defp validate_lte(%{lte: nil}, _), do: :ok
  defp validate_lte(%{lte: {%Decimal{} = lte, opts}}, %Decimal{} = value) do
    case Decimal.lte?(value, lte) do
      true -> :ok
      false -> {:error, issue(opts.error, %{lte: lte, value: value})}
    end
  end
end
