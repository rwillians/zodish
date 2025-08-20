defmodule Zodish.Type.Any do
  @moduledoc ~S"""
  Describes a type that accepts any value.
  """

  alias Zodish.Type.Any, as: TAny

  @type t :: %TAny{}

  defstruct []

  @doc false
  def new, do: %TAny{}
end

defimpl Zodish.Type, for: Zodish.Type.Any do
  alias Zodish.Type.Any, as: TAny

  @impl Zodish.Type
  def parse(%TAny{}, value), do: {:ok, value}
end
