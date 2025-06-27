defmodule Zodish.Type.Atom do
  @moduledoc ~S"""
  This module describes a Zodish atom type.
  """

  alias __MODULE__, as: TAtom

  @type t() :: %TAtom{
          coerce: boolean() | :unsafe
        }

  defstruct coerce: false

  def new(opts \\ []) do
    Enum.reduce(opts, %TAtom{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Atom")
    end)
  end

  def coerce(%TAtom{} = type, value \\ true)
      when is_boolean(value)
      when value == :unsafe,
      do: %{type | coerce: value}
end

defimpl Zodish.Type, for: Zodish.Type.Atom do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Atom, as: TAtom

  @impl Zodish.Type
  def parse(%TAtom{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("Is required")}
  defp validate_required(_), do: :ok

  defp coerce(%{coerce: true}, value) when is_atom(value), do: {:ok, value}
  defp coerce(%{coerce: true}, <<_, _::binary>> = value) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ -> {:error, issue("Cannot coerce string #{inspect(value)} into an existing atom")}
  end
  defp coerce(%{coerce: :unsafe}, <<_, _::binary>> = value) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ -> {:ok, String.to_atom(value)}
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_atom(value), do: :ok
  defp validate_type(value), do: {:error, issue("Expected an atom, got #{typeof(value)}")}
end
