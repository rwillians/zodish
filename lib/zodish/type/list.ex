defmodule Zodish.Type.List do
  @moduledoc ~S"""
  This module describes a Zodish list type.
  """

  import Kernel, except: [min: 2, max: 2]
  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TList

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %TList{
          inner_type: inner_type,
          length: Zodish.Option.t(non_neg_integer()) | nil,
          min: Zodish.Option.t(non_neg_integer()) | nil,
          max: Zodish.Option.t(non_neg_integer()) | nil
        }

  defstruct inner_type: nil,
            length: nil,
            min: nil,
            max: nil

  @doc ~S"""
  Creates a new List type.
  """
  def new(%_{} = inner_type, opts \\ []) do
    Enum.reduce(opts, %TList{inner_type: inner_type}, fn
      {:length, {value, opts}}, type -> length(type, value, opts)
      {:length, value}, type -> length(type, value)
      {:min, {value, opts}}, type -> min(type, value, opts)
      {:min, value}, type -> min(type, value)
      {:max, {value, opts}}, type -> max(type, value, opts)
      {:max, value}, type -> max(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.List")
    end)
  end

  @opts [error: "expected list to have exactly {{length | item}}, got {{actual_length | item}}"]
  def length(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | length: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected list to have at least {{min | item}}, got {{actual_length | item}}"]
  def min(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | min: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected list to have at most {{max | item}}, got {{actual_length | item}}"]
  def max(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | max: {value, merge_opts(@opts, opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.List do
  import Enum, only: [reduce: 3, with_index: 1]
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [flatten: 1, issue: 1, issue: 2, parse_score: 1, prepend_path: 2]

  alias Zodish.Issue
  alias Zodish.Type.List, as: TList

  @impl Zodish.Type
  def parse(%TList{} = type, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(value),
         :ok <- validate_length(type, value),
         :ok <- validate_min(type, value),
         :ok <- validate_max(type, value),
         do: parse_items(type, value)
  end

  @impl Zodish.Type
  def to_spec(%TList{length: {n, _}} = type) when n > 0, do: [Zodish.Type.to_spec(type.inner_type), {:..., [], []}]
  def to_spec(%TList{min: {n, _}} = type) when n > 0, do: [Zodish.Type.to_spec(type.inner_type), {:..., [], []}]
  def to_spec(%TList{} = type), do: [Zodish.Type.to_spec(type.inner_type)]

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp validate_type([]), do: :ok
  defp validate_type([_ | _] = value) do
    case Keyword.keyword?(value) do
      false -> :ok
      true -> {:error, issue("expected a list, got a keyword list")}
    end
  end
  defp validate_type(value), do: {:error, issue("expected a list, got #{typeof(value)}")}

  defp validate_length(%TList{length: nil}, _), do: :ok
  defp validate_length(%TList{length: {length, opts}}, value) do
    actual_length = length(value)

    case actual_length == length do
      true -> :ok
      false -> {:error, issue(opts.error, %{length: length, actual_length: actual_length})}
    end
  end

  defp validate_min(%TList{min: nil}, _), do: :ok
  defp validate_min(%TList{min: {min, opts}}, value) do
    actual_length = length(value)

    case actual_length >= min do
      true -> :ok
      false -> {:error, issue(opts.error, %{min: min, actual_length: actual_length})}
    end
  end

  defp validate_max(%TList{max: nil}, _), do: :ok
  defp validate_max(%TList{max: {max, opts}}, value) do
    actual_length = length(value)

    case actual_length <= max do
      true -> :ok
      false -> {:error, issue(opts.error, %{max: max, actual_length: actual_length})}
    end
  end

  defp parse_items(%TList{inner_type: inner_type}, value) do
    {parsed, issues} =
      value
      |> with_index()
      |> reduce({[], []}, fn {item, index}, {acc_items, acc_issues} ->
        case Zodish.Type.parse(inner_type, item) do
          {:ok, parsed} -> {[parsed | acc_items], acc_issues}
          {:error, issue} -> {acc_items, [prepend_path(issue, [index]) | acc_issues]}
        end
      end)

    issue = %Issue{
      message: "one or more items of the list did not match the expected type",
      issues: issues
    }

    case issues do
      [] -> {:ok, :lists.reverse(parsed)}
      [_ | _] -> {:error, %{flatten(issue) | parse_score: parse_score(parsed)}}
    end
  end
end
