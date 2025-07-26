defmodule Zodish.Type.Record do
  alias __MODULE__, as: TRecord
  alias Zodish.Type.Any, as: TAny
  alias Zodish.Type.String, as: TString

  @type t() :: %TRecord{
          keys_schema: Zodish.Type.t(),
          values_schema: Zodish.Type.t()
        }

  defstruct keys_schema: nil,
            values_schema: nil

  @doc ~S"""
  """
  @spec new(opts :: keyword()) :: t()

  def new(opts \\ []) do
    type = %TRecord{
      keys_schema: TString.new(min_length: 1),
      values_schema: TAny.new()
    }

    Enum.reduce(opts, type, fn
      {:keys, value}, type -> keys(type, value)
      {:values, value}, type -> values(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)}")
    end)
  end

  #
  #   PRIVATE
  #

  defp keys(%TRecord{} = schema, %TString{} = value), do: %{schema | keys_schema: value}
  defp keys(%TRecord{}, %_{}), do: raise(ArgumentError, "Record keys must be string")

  defp values(%TRecord{} = schema, %_{} = value), do: %{schema | values_schema: value}
end

defimpl Zodish.Type, for: Zodish.Type.Record do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [flatten: 1, issue: 1, parse_score: 1, prepend_path: 2]

  alias Zodish.Issue, as: Issue
  alias Zodish.Type.Record, as: TRecord

  @impl Zodish.Type
  def parse(%TRecord{} = schema, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(value),
         do: parse_value(schema, value)
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp validate_type(%{} = value) when not is_struct(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected a map, got #{typeof(value)}")}

  defp parse_value(%TRecord{} = schema, value) do
    {parsed, issues} =
      Enum.reduce(value, {%{}, []}, fn {key, val}, {acc_parsed, acc_issues} ->
        with {:ok, key} <- Zodish.Type.parse(schema.keys_schema, key),
            {:ok, val} <- Zodish.Type.parse(schema.values_schema, val) do
          {Map.put(acc_parsed, key, val), acc_issues}
        else
          {:error, issue} -> {acc_parsed, [prepend_path(issue, [key]) | acc_issues]}
        end
      end)

    issue = flatten(%Issue{
      message: "one or more fields failed validation",
      issues: :lists.reverse(issues)
    })

    case issues do
      [] -> {:ok, parsed}
      [_ | _] -> {:error, %{issue | parse_score: parse_score(parsed)}}
    end
  end
end
