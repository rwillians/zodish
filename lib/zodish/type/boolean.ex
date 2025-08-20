defmodule Zodish.Type.Boolean do
  @moduledoc ~S"""
  This module describes a Zodish boolean type.
  """

  alias Zodish.Type.Boolean, as: TBoolean

  @type t() :: %TBoolean{
          coerce: boolean()
        }

  defstruct coerce: false

  @doc false
  def new(opts \\ []) do
    Enum.reduce(opts, %TBoolean{}, fn
      {:coerce, coerce}, type -> coerce(type, coerce)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Boolean")
    end)
  end

  @doc false
  def coerce(%TBoolean{} = type, value \\ true)
      when is_boolean(value),
      do: %TBoolean{type | coerce: value}
end

defimpl Zodish.Type, for: Zodish.Type.Boolean do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Boolean, as: TBoolean

  @impl Zodish.Type
  def parse(%TBoolean{} = type, value) do
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

  @truthy ["true", "1", "yes", "y", "on", "enabled"]
  @falsey ["false", "0", "no", "n", "off", "disabled"]
  defp coerce(%{coerce: true}, value) when is_boolean(value), do: {:ok, value}
  defp coerce(%{coerce: true}, <<value::binary>>) when value in @truthy, do: {:ok, true}
  defp coerce(%{coerce: true}, <<value::binary>>) when value in @falsey, do: {:ok, false}
  defp coerce(%{coerce: true}, 1), do: {:ok, true}
  defp coerce(%{coerce: true}, 0), do: {:ok, false}
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_boolean(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected a boolean, got #{typeof(value)}")}
end
