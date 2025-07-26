defmodule Zodish.Type.Tuple do
  @moduledoc ~S"""
  This module describes a Zodish tuple type.
  """

  alias __MODULE__, as: TTuple

  @type t() :: %TTuple{
          elements: [Zodish.Type.t(), ...]
        }

  defstruct elements: []

  def new([_, _ | _] = elements), do: %TTuple{elements: elements}

  def new(elements)
      when is_list(elements) and length(elements) < 2,
      do: raise(ArgumentError, "Tuple must have at least two elements")
end

defimpl Zodish.Type, for: Zodish.Type.Tuple do
  import Enum, only: [reduce: 3, with_index: 1]
  import List, only: [to_tuple: 1]
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [flatten: 1, issue: 1, prepend_path: 2]

  alias Zodish.Issue
  alias Zodish.Type.Tuple, as: TTuple

  @impl Zodish.Type
  def parse(%TTuple{} = type, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(value),
         {:ok, value} <- parse_tuple(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp validate_type(value) when is_tuple(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected a tuple, got #{typeof(value)}")}

  defp parse_tuple(%TTuple{elements: elements}, value)
       when length(elements) != tuple_size(value),
       do: {:error, issue("expected a tuple of length #{length(elements)}, got length #{tuple_size(value)}")}

  defp parse_tuple(%TTuple{} = type, value) do
    {parsed_elems, issues} =
      type.elements
      |> with_index()
      |> reduce({[], []}, fn {elem_type, index}, {acc_elems, acc_issues} ->
        case Zodish.Type.parse(elem_type, elem(value, index)) do
          {:ok, parsed} -> {[parsed | acc_elems], acc_issues}
          {:error, issue} -> {acc_elems, [prepend_path(issue, [index]) | acc_issues]}
        end
      end)

    issue = %Issue{
      message: "one or more elements of the tuple did not match the expected type",
      issues: issues,
    }

    case issues do
      [] -> {:ok, to_tuple(:lists.reverse(parsed_elems))}
      [_ | _] -> {:error, %{flatten(issue) | parse_score: length(parsed_elems)}}
    end
  end
end
