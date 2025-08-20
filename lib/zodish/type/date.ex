defmodule Zodish.Type.Date do
  @moduledoc ~S"""
  This module describes a Zodish date type.
  """

  alias __MODULE__, as: TDate

  @type t() :: %TDate{
          coerce: boolean()
        }

  defstruct coerce: false

  @doc false
  def new(opts \\ []) do
    Enum.reduce(opts, %TDate{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{key} for Zodish.Type.Date")
    end)
  end

  @doc false
  def coerce(%TDate{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}
end

defimpl Zodish.Type, for: Zodish.Type.Date do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Date, as: TDate

  @impl Zodish.Type
  def infer(%TDate{}) do
    quote(do: Date.t())
  end

  @impl Zodish.Type
  def parse(%TDate{} = type, value) do
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
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, issue("expected a valid ISO8601 date string, got #{inspect(value)}")}
    end
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(%Date{}), do: :ok
  defp validate_type(value), do: {:error, issue("expected a Date, got #{typeof(value)}")}
end
