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

  def new(nil), do: raise(ArgumentError, "Literal type cannot be nil, use `Z.optional/1` instead")
  def new(value), do: %TLiteral{value: value}
end

defimpl Zodish.Type, for: Zodish.Type.Literal do
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Literal, as: TLiteral

  @impl Zodish.Type
  def parse(%TLiteral{}, nil), do: {:error, issue("Is required")}
  def parse(%TLiteral{value: same}, same), do: {:ok, same}
  def parse(%TLiteral{value: expected}, actual), do: {:error, issue("Expected to be #{inspect(expected)}, got #{inspect(actual)}")}
end
