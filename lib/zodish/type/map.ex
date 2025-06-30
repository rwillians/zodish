defmodule Zodish.Type.Map do
  alias __MODULE__, as: TMap

  @type shape() :: %{
          required(atom()) => Zodish.Type.t()
        }

  @type t() :: %TMap{
          mode: :strip | :strict,
          shape: shape()
        }

  defstruct mode: :strip,
            shape: %{}

  def new(mode \\ :strip, shape)
  def new(_, %{} = shape) when map_size(shape) == 0, do: raise(ArgumentError, "Shape cannot be empty")
  def new(:strip, %{} = shape), do: strip(%TMap{shape: shape})
  def new(:strict, %{} = shape), do: strict(%TMap{shape: shape})

  def strip(%TMap{} = type), do: %{type | mode: :strip}

  def strict(%TMap{} = type), do: %{type | mode: :strict}
end

defimpl Zodish.Type, for: Zodish.Type.Map do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [flatten: 1, issue: 1, prepend_path: 2, score: 1]

  alias Zodish.Issue
  alias Zodish.Type.Map, as: TMap

  @impl Zodish.Type
  def parse(%TMap{} = schema, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(value),
         do: parse_shape(schema, value)
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("Is required")}
  defp validate_required(_), do: :ok

  defp validate_type(value) when is_non_struct_map(value), do: :ok
  defp validate_type(value), do: {:error, issue("Expected a map, got #{typeof(value)}")}

  defp get(map, key) do
    {:ok, value} =
      with :error <- Map.fetch(map, key),
           :error <- Map.fetch(map, to_string(key)),
           do: {:ok, nil}

    value
  end

  defp parse_known_fields(shape, map) do
    Enum.reduce(shape, {%{}, []}, fn {key, type}, {acc_parsed, acc_issues} ->
      case Zodish.Type.parse(type, get(map, key)) do
        {:ok, val} -> {Map.put(acc_parsed, key, val), acc_issues}
        {:error, issue} -> {acc_parsed, [prepend_path(issue, [key]) | acc_issues]}
      end
    end)
  end

  defp parse_shape(%TMap{mode: :strip} = type, map) do
    {parsed, issues} = parse_known_fields(type.shape, map)

    issue = flatten(%Issue{
      message: "One or more fields failed validation",
      issues: :lists.reverse(issues)
    })

    case issues do
      [] -> {:ok, parsed}
      [_ | _] -> {:error, %{issue | parse_score: score(parsed)}}
    end
  end

  defp parse_shape(%TMap{mode: :strict} = type, value) do
    known_fields_index =
      Map.keys(type.shape)
      |> Enum.map(&to_string/1)
      |> Enum.map(&{&1, true})
      |> Enum.into(%{})

    given_fields = Enum.map(Map.keys(value), &to_string/1)

    unknown_field_issues =
      for key <- given_fields,
          not Map.has_key?(known_fields_index, key),
          do: prepend_path(issue("Unknown field"), [key])

    {parsed, other_issues} = parse_known_fields(type.shape, value)
    issues = unknown_field_issues ++ other_issues

    issue = flatten(%Issue{
      message: "One or more fields failed validation",
      issues: :lists.reverse(issues)
    })

    case issues do
      [] -> {:ok, parsed}
      [_ | _] -> {:error, %{issue | parse_score: score(parsed)}}
    end
  end
end
