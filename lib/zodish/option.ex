defmodule Zodish.Option do
  @moduledoc ~S"""
  Type options have their own set of options, such as a custom error
  message. This module defines how to type those and how to merge
  default options with user-defined options.
  """

  @typedoc false
  @type t() :: t(any())
  @type t(inner_type) :: {inner_type, %{error: String.t()}}

  @doc ~S"""
  Merges two sets of options where `b` overrides `a`.
  """
  def merge_opts(a, b), do: Map.merge(Enum.into(a, %{}), Enum.into(b, %{}))
end
