defmodule ZodishTest do
  use ExUnit.Case, async: true

  alias Zodish, as: Z

  defmodule Address do
    defstruct [:line_1, :line_2, :city, :state, :zip]
  end

  doctest Zodish.Helpers
  doctest Zodish.Issue
  doctest Zodish
end
