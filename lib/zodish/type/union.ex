defmodule Zodish.Type.Union do
  alias __MODULE__, as: TUnion

  @type t() :: t(Zodish.Type.t())
  @type t(inner_types) :: %TUnion{
          inner_types: inner_types
        }

  defstruct inner_types: []

  @doc false
  def new([%_{}, %_{} | _] = inner_types), do: %TUnion{inner_types: inner_types}
  def new(inner_types)
      when is_list(inner_types),
      do: raise(ArgumentError, "Union type must be a list of at least two types")
end

defimpl Zodish.Type, for: Zodish.Type.Union do
  alias Zodish.Issue, as: Issue
  alias Zodish.Type.Union, as: TUnion

  @impl Zodish.Type
  def infer(%TUnion{}) do
    quote(do: term())
  end

  @impl Zodish.Type
  def parse(%TUnion{} = type, value) do
    {parsed, issues} =
      Enum.reduce_while(type.inner_types, {nil, []}, fn inner_type, {_, issues} ->
        case Zodish.Type.parse(inner_type, value) do
          {:ok, parsed_value} -> {:halt, {parsed_value, []}}
          {:error, issue} -> {:cont, {nil, [issue | issues]}}
        end
      end)

    sorted_issues = Enum.sort_by(issues, & &1.parse_score, :desc)

    case List.first(sorted_issues) do
      nil -> {:ok, parsed}
      %Issue{} = issue -> {:error, issue}
    end
  end
end
