defmodule Zodish.Issue do
  @moduledoc ~S"""
  Represents an issue while parsing a value.
  """

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

  def issue(message)
      when is_binary(message),
      do: %Issue{message: message}

  def issue(message, %{} = ctx) when is_binary(message) do
    message
    |> replace_variables(ctx)
    |> replace_pluralize_slots(ctx)
    |> issue()
  end

  #
  #   PRIVATE
  #

  defp replace_variables(str, ctx) do
    Enum.reduce(ctx, str, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)
  end

  @slot ~r/\{\{([^\|]+)\|([^\}]+)\}\}/
  defp replace_pluralize_slots(str, ctx) do
    Regex.replace(@slot, str, fn _slot, count_field, word ->
      ctx
      |> Map.fetch!(String.to_existing_atom(count_field))
      |> pluralize(word)
    end)
  end
end
