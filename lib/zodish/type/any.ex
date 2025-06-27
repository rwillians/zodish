defmodule Zodish.Type.Any do
  @moduledoc ~S"""
  Describes a type that accepts any value.
  """

  alias Zodish.Type.Any, as: TAny

  @type t :: %TAny{}

  defstruct []

  def new, do: %TAny{}
end

defimpl Zodish.Parseable, for: Zodish.Type.Any do
  alias Zodish.Type.Any, as: TAny

  @impl Zodish.Parseable
  def parse(%TAny{}, value), do: {:ok, value}
end
