defprotocol Zodish.Type do
  @moduledoc ~S"""
  Protocol for parsing values based on Zodish types.
  """

  @doc ~S"""
  Returns AST representing the given Zodish type in Elixir.
  """
  @spec infer(type :: t()) :: Macro.t()

  def infer(type)

  @doc ~S"""
  Parses a value based on the given Zodish type.
  """
  @spec parse(type :: t(), value :: any()) ::
          {:ok, any()}
          | {:error, String.t()}

  def parse(type, value)
end
