defmodule Zodish.Type do
  @moduledoc ~S"""
  Helper module for creating Zodish types.
  """

  defmacro __using__(_) do
    quote do
      import Zodish.Option, only: [merge_opts: 2]
    end
  end
end
