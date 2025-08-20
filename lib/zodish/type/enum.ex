defmodule Zodish.Type.Enum do
  @moduledoc ~S"""
  This module describes a Zodish enum type (atoms only).
  """

  alias __MODULE__, as: TEnum

  @type t() :: %TEnum{
          coerce: boolean() | :unsafe,
          values: [atom(), ...]
        }

  defstruct coerce: false,
            values: []

  @doc false
  def new([{_, _} | _] =opts) do
    Enum.reduce(opts, %TEnum{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:values, values}, type -> values(type, values)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Enum")
    end)
  end

  def new([head | _] = values)
      when is_atom(head),
      do: new(values: values)

  @doc false
  def coerce(%TEnum{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  @doc false
  def values(%TEnum{} = type, [_ | _] = values), do: set_values(type, values)

  #
  #  PRIVATE
  #

  defp set_values(type, []),
    do: %{type | values: :lists.reverse(type.values)}

  defp set_values(type, [head | tail])
       when is_atom(head),
       do: set_values(%{type | values: [head | type.values]}, tail)

  defp set_values(_, [head | _]),
    do: raise(ArgumentError, "Expected values for Zodish.Type.Enum to be atoms, got #{inspect(head)}")
end

defimpl Zodish.Type, for: Zodish.Type.Enum do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Enum, as: TEnum

  @impl Zodish.Type
  def infer(%TEnum{}) do
    # @todo
    quote(do: atom())
  end

  @impl Zodish.Type
  def parse(%TEnum{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         :ok <- validate_inclusion(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp coerce(_, value) when is_atom(value), do: {:ok, value}
  defp coerce(%{coerce: true} = type, <<value::binary>>) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ ->
      allowed_values = Enum.map(type.values, &Atom.to_string/1)

      if value in allowed_values,
        do: {:ok, String.to_atom(value)},
        else: {:error, issue("is invalid")}
  end
  defp coerce(_, value), do: {:ok, value}

  defp validate_type(value) when is_atom(value), do: :ok
  defp validate_type(value), do: {:error, issue("expected an atom, got #{typeof(value)}")}

  defp validate_inclusion(type, value) do
    if value in type.values,
      do: :ok,
      else: {:error, issue("is invalid")}
  end
end
