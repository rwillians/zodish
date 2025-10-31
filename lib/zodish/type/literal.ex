defmodule Zodish.Type.Literal do
  @moduledoc ~S"""
  Describes a type that only accepts a specific value.
  """

  alias __MODULE__, as: TLiteral

  @type t() :: t(any())
  @type t(inner_type) :: %TLiteral{
          value: inner_type
        }

  defstruct value: nil

  @doc ~S"""
  Creates a new Literal type.
  """
  def new(nil), do: raise(ArgumentError, "Literal type cannot be nil, use literal in combination with `Z.optional/1` instead")
  def new(value), do: %TLiteral{value: value}
end

defimpl Zodish.Type, for: Zodish.Type.Literal do
  import Zodish.Helpers, only: [infer_type: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Literal, as: TLiteral

  @impl Zodish.Type
  def parse(%TLiteral{}, nil), do: {:error, issue("is required")}
  def parse(%TLiteral{value: same}, same), do: {:ok, same}
  def parse(%TLiteral{value: expected}, actual), do: {:error, issue("expected to be exactly #{inspect(expected)}, got #{inspect(actual)}")}

  @impl Zodish.Type
  def to_spec(%TLiteral{} = type), do: infer_type(type.value)
end
