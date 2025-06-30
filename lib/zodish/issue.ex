defmodule Zodish.Issue do
  @moduledoc ~S"""
  Represents an issue while parsing a value.
  """

  import Enum, only: [map: 2, reduce: 3]
  import Zodish.Helpers, only: [pluralize: 2]

  alias __MODULE__, as: Issue

  @type segment() :: atom() | non_neg_integer() | String.t()

  @type t() :: %Issue{
          path: [segment()],
          message: String.t(),
          issues: [t()],
          parse_score: non_neg_integer()
        }

  defstruct path: [],
            message: nil,
            issues: [],
            parse_score: 0

  @doc ~S"""
  Creates a new issue with the given message.

      iex> Zodish.Issue.issue("An error occurred")
      %Zodish.Issue{message: "An error occurred"}

  """
  @spec issue(message :: String.t()) :: t()

  def issue(message)
      when is_binary(message),
      do: %Issue{message: message}

  @doc ~S"""
  Creates a new issue after replacing any variables in the given
  message for their value in the given context map.

      iex> Zodish.Issue.issue("The value of {{key}} is invalid", %{key: "foo"})
      %Zodish.Issue{message: "The value of foo is invalid"}

  """
  @spec issue(message :: String.t(), ctx :: map()) :: t()

  def issue(message, %{} = ctx) when is_binary(message) do
    message
    |> replace_variables(ctx)
    |> replace_pluralize_slots(ctx)
    |> issue()
  end

  @doc ~S"""
  Appends a set of segments to the given issue's path.

      iex> %Zodish.Issue{path: [:a], message: "An error occurred"}
      iex> |> Zodish.Issue.append_path([:b, :c])
      %Zodish.Issue{path: [:a, :b, :c], message: "An error occurred"}

  """
  @spec append_path(issue :: t(), segments :: [segment()]) :: t()

  def append_path(%Issue{} = issue, segments)
      when is_list(segments),
      do: %{issue | path: issue.path ++ segments}

  @doc ~S"""
  Prepends a set of segments to the given issue's path.

      iex> %Zodish.Issue{path: [:c], message: "An error occurred"}
      iex> |> Zodish.Issue.prepend_path([:a, :b])
      %Zodish.Issue{path: [:a, :b, :c], message: "An error occurred"}

  """
  @spec prepend_path(issue :: t(), segments :: [segment()]) :: t()

  def prepend_path(%Issue{} = issue, segments)
      when is_list(segments),
      do: %{issue | path: segments ++ issue.path}

  @doc ~S"""
  Flattens the issues of a given `Zodish.Issue` struct.

      iex> Zodish.Issue.flatten(%Zodish.Issue{message: "One or more items failed validation", issues: [
      iex>   %Zodish.Issue{
      iex>     path: [0],
      iex>     message: "One or more fields failed validation",
      iex>     issues: [%Zodish.Issue{path: [:email], message: "Is required"}],
      iex>     parse_score: 1
      iex>   },
      iex>   %Zodish.Issue{
      iex>     path: [1],
      iex>     message: "One or more fields failed validation",
      iex>     issues: [%Zodish.Issue{path: [:name], message: "Is required"}],
      iex>     parse_score: 1,
      iex>   }
      iex> ]})
      %Zodish.Issue{message: "One or more items failed validation", issues: [
        %Zodish.Issue{path: [0, :email], message: "Is required"},
        %Zodish.Issue{path: [1, :name], message: "Is required"}
      ]}

  """
  @spec flatten(issue :: t()) :: t()

  def flatten(%Issue{issues: []} = issue), do: issue
  def flatten(%Issue{} = issue), do: %{issue | issues: flatten_issues(issue.issues, issue.path)}

  @doc ~S"""
  Calculates the parse score of a value.

      iex> Zodish.Issue.score(%{ # +1
      iex>   foo: [ # +1
      iex>     %{bar: :bar}, # +2
      iex>     %{baz: {:ok, :baz}} # +4
      iex>   ]
      iex> })
      8

  """
  @spec score(value :: any()) :: non_neg_integer()

  def score(value), do: score(value, 0)

  defp score(nil, acc), do: acc
  defp score(value, acc) when is_atom(value), do: acc + 1
  defp score(value, acc) when is_binary(value), do: acc + 1
  defp score(value, acc) when is_bitstring(value), do: acc + 1
  defp score(value, acc) when is_boolean(value), do: acc + 1
  defp score(value, acc) when is_float(value), do: acc + 1
  defp score(value, acc) when is_function(value), do: acc + 1
  defp score(value, acc) when is_integer(value), do: acc + 1
  defp score(value, acc) when is_pid(value), do: acc + 1
  defp score(value, acc) when is_port(value), do: acc + 1
  defp score(value, acc) when is_reference(value), do: acc + 1
  defp score(value, acc) when is_tuple(value), do: acc + 1 + tuple_size(value)
  defp score([], acc), do: acc + 1
  defp score([_ | _] = value, acc), do: acc + 1 + Enum.sum(Enum.map(value, &score/1))
  defp score(%_{} = value, acc), do: acc + 1 + Enum.sum(Enum.map(Map.values(Map.from_struct(value)), &score/1))
  defp score(%{} = value, acc), do: acc + 1 + Enum.sum(Enum.map(Map.values(value), &score/1))

  #
  #   PRIVATE
  #

  defp replace_variables(str, ctx) do
    reduce(ctx, str, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)
  end

  @slot ~r/\{\{([^\s\|]+)\s?\|\s?([^\}]+)\}\}/
  defp replace_pluralize_slots(str, ctx) do
    Regex.replace(@slot, str, fn _slot, count_field, word ->
      count = Map.fetch!(ctx, String.to_existing_atom(count_field))
      #                              ↑ this will only raise if you're
      #                                trying to pluralize a variable
      #                                that doesn't exist in the ctx
      "#{count} #{pluralize(count, word)}"
    end)
  end

  defp flatten_issues([], _path), do: []

  defp flatten_issues([_ | _] = issues, path) do
    reduce(issues, [], fn issue, acc ->
      case issue.issues do
        [] -> acc ++ [prepend_path(issue, path)]
        [_ | _] -> acc ++ flatten_issues(map(issue.issues, &prepend_path(&1, issue.path)), path)
      end
    end)
  end
end
