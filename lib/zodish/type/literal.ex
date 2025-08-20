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

  @doc false
  def new(nil), do: raise(ArgumentError, "Literal type cannot be nil, use `Z.optional/1` instead")
  def new(value), do: %TLiteral{value: value}
end

defimpl Zodish.Type, for: Zodish.Type.Literal do
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Literal, as: TLiteral

  @impl Zodish.Type
  def infer(%TLiteral{value: nil}), do: quote(do: nil)
  def infer(%TLiteral{value: <<_::binary>>}), do: quote(do: binary())
  def infer(%TLiteral{value: value}) when is_atom(value), do: quote(do: atom())
  def infer(%TLiteral{value: bool}) when is_boolean(bool), do: quote(do: boolean())
  def infer(%TLiteral{value: n}) when is_integer(n), do: quote(do: integer())
  def infer(%TLiteral{value: n}) when is_float(n), do: quote(do: float())
  def infer(%TLiteral{value: %mod{}}), do: quote(do: %unquote(mod){})
  def infer(%TLiteral{value: %{}}), do: quote(do: map())
  def infer(%TLiteral{value: []}), do: quote(do: list())
  def infer(%TLiteral{value: [{_ | _} | _]}), do: quote(do: keyword())
  def infer(%TLiteral{value: [_ | _]}), do: quote(do: list())
  def infer(%TLiteral{}), do: quote(do: term())

  @impl Zodish.Type
  def parse(%TLiteral{}, nil), do: {:error, issue("is required")}
  def parse(%TLiteral{value: same}, same), do: {:ok, same}
  def parse(%TLiteral{value: expected}, actual), do: {:error, issue("expected to be exactly #{inspect(expected)}, got #{inspect(actual)}")}
end
