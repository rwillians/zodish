defmodule Zodish.Type.DateTime do
  @moduledoc ~S"""
  This module describes a Zodish date-time type.
  """

  alias __MODULE__, as: TDateTime

  @type t() :: %TDateTime{
          coerce: boolean()
        }

  defstruct coerce: false

  @doc ~S"""
  Creates a new DateTime type.
  """
  def new(opts \\ []) do
    Enum.reduce(opts, %TDateTime{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.DateTime")
    end)
  end

  @doc ~S"""
  Either enables or disables coercion for the given DateTime type.
  """
  def coerce(%TDateTime{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}
end

defimpl Zodish.Type, for: Zodish.Type.DateTime do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.DateTime, as: TDateTime

  @impl Zodish.Type
  def parse(%TDateTime{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp coerce(%{coerce: true}, <<value::binary>>) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> {:ok, datetime}
      {:error, _} -> {:error, issue("expected a valid ISO8601 date-time string, got #{inspect(value)}")}
    end
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(%DateTime{}), do: :ok
  defp validate_type(value), do: {:error, issue("expected a DateTime, got #{typeof(value)}")}
end
