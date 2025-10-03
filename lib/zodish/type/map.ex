defmodule Zodish.Type.Map do
  import Zodish.Helpers, only: [take_sorted: 2]

  alias __MODULE__, as: TMap

  @type shape() :: %{
          required(atom()) => Zodish.Type.t()
        }

  @type t() :: %TMap{
          coerce: boolean(),
          mode: :strip | :strict,
          shape: shape()
        }

  defstruct coerce: false,
            mode: :strip,
            shape: %{}

  @doc ~S"""
  Creates a new Map type.
  """
  def new([{_, _} | _] = opts) do
    Enum.reduce(opts, %TMap{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:mode, :strip}, type -> strip(type)
      {:mode, :strict}, type -> strict(type)
      {:shape, shape}, type -> shape(type, shape)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.String")
    end)
  end
  def new(%{} = shape), do: new(mode: :strip, shape: shape)

  @doc ~S"""
  Creates a new Map type.
  """
  def new(:strip, %{} = shape), do: new(mode: :strip, shape: shape)
  def new(:strict, %{} = shape), do: new(mode: :strict, shape: shape)
  def new([{_, _} | _] = opts, %{} = shape), do: new(opts ++ [shape: shape])

  @doc ~S"""
  Either enables or disables coercion for the given Map type.
  """
  def coerce(%TMap{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  def strip(%TMap{} = type), do: %{type | mode: :strip}

  def strict(%TMap{} = type), do: %{type | mode: :strict}

  def shape(%TMap{} = type, %{} = shape)
      when is_non_struct_map(shape) and map_size(shape) > 0,
      do: %{type | shape: shape}
end

defimpl Zodish.Type, for: Zodish.Type.Map do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [flatten: 1, issue: 1, parse_score: 1, prepend_path: 2]

  alias Zodish.Issue
  alias Zodish.Type.Map, as: TMap

  @impl Zodish.Type
  def parse(%TMap{} = schema, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(schema, value),
         :ok <- validate_type(value),
         do: parse_value(schema, value)
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp coerce(%TMap{coerce: false}, value), do: {:ok, value}
  defp coerce(%TMap{coerce: true}, %_{} = value), do: {:ok, Map.drop(Map.from_struct(value), [:__meta__])}
  defp coerce(%TMap{coerce: true}, %{} = value), do: {:ok, value}
  defp coerce(%TMap{coerce: true}, [{_, _} | _] = value), do: {:ok, Enum.into(value, %{})}
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_non_struct_map(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected a map, got #{typeof(value)}")}

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

  defp parse_value(%TMap{mode: :strip} = type, map) do
    {parsed, issues} = parse_known_fields(type.shape, map)

    issue =
      flatten(%Issue{
        message: "one or more fields failed validation",
        issues: :lists.reverse(issues)
      })

    case issues do
      [] -> {:ok, parsed}
      [_ | _] -> {:error, %{issue | parse_score: parse_score(parsed)}}
    end
  end

  defp parse_value(%TMap{mode: :strict} = type, value) do
    known_fields_index =
      Map.keys(type.shape)
      |> Enum.map(&to_string/1)
      |> Enum.map(&{&1, true})
      |> Enum.into(%{})

    given_fields = Enum.map(Map.keys(value), &to_string/1)

    unknown_field_issues =
      for key <- given_fields,
          not Map.has_key?(known_fields_index, key),
          do: prepend_path(issue("unknown field"), [key])

    {parsed, other_issues} = parse_known_fields(type.shape, value)
    issues = unknown_field_issues ++ other_issues

    issue =
      flatten(%Issue{
        message: "one or more fields failed validation",
        issues: :lists.reverse(issues)
      })

    case issues do
      [] -> {:ok, parsed}
      [_ | _] -> {:error, %{issue | parse_score: parse_score(parsed)}}
    end
  end
end
