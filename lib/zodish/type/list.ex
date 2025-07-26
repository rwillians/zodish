defmodule Zodish.Type.List do
  @moduledoc ~S"""
  This module describes a Zodish list type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TList

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %TList{
          inner_type: inner_type,
          exact_length: Zodish.Option.t(non_neg_integer()) | nil,
          min_length: Zodish.Option.t(non_neg_integer()) | nil,
          max_length: Zodish.Option.t(non_neg_integer()) | nil
        }

  defstruct inner_type: nil,
            exact_length: nil,
            min_length: nil,
            max_length: nil

  def new(%_{} = inner_type, opts \\ []) do
    Enum.reduce(opts, %TList{inner_type: inner_type}, fn
      {:exact_length, {value, opts}}, type -> exact_length(type, value, opts)
      {:exact_length, value}, type -> exact_length(type, value)
      {:min_length, {value, opts}}, type -> min_length(type, value, opts)
      {:min_length, value}, type -> min_length(type, value)
      {:max_length, {value, opts}}, type -> max_length(type, value, opts)
      {:max_length, value}, type -> max_length(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.List")
    end)
  end

  @opts [error: "expected list to have exactly {{exact_length | item}}, got {{actual_length | item}}"]
  def exact_length(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | exact_length: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected list to have at least {{min_length | item}}, got {{actual_length | item}}"]
  def min_length(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | min_length: {value, merge_opts(@opts, opts)}}

  @opts [error: "expected list to have at most {{max_length | item}}, got {{actual_length | item}}"]
  def max_length(%TList{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | max_length: {value, merge_opts(@opts, opts)}}
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
         :ok <- validate_exact_length(type, value),
         :ok <- validate_min_length(type, value),
         :ok <- validate_max_length(type, value),
         do: parse_items(type, value)
  end

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

  defp validate_exact_length(%TList{exact_length: nil}, _), do: :ok
  defp validate_exact_length(%TList{exact_length: {exact_length, opts}}, value) do
    actual_length = length(value)

    case actual_length == exact_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{exact_length: exact_length, actual_length: actual_length})}
    end
  end

  defp validate_min_length(%TList{min_length: nil}, _), do: :ok
  defp validate_min_length(%TList{min_length: {min_length, opts}}, value) do
    actual_length = length(value)

    case actual_length >= min_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{min_length: min_length, actual_length: actual_length})}
    end
  end

  defp validate_max_length(%TList{max_length: nil}, _), do: :ok
  defp validate_max_length(%TList{max_length: {max_length, opts}}, value) do
    actual_length = length(value)

    case actual_length <= max_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{max_length: max_length, actual_length: actual_length})}
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
