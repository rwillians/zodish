defmodule ZodishTest do
  use ExUnit.Case, async: true

  alias Zodish, as: Z

  doctest Zodish.Helpers
  doctest Zodish.Issue
  doctest Zodish
end
