defprotocol Zodish.Type do
  @moduledoc ~S"""
  Protocol for parsing values based on Zodish schemas.
  """

  @doc ~S"""
  Parses a value based on the given Zodish schema.
  """
  @spec parse(schema :: t(), value :: any()) ::
          {:ok, any()}
          | {:error, Zodish.Issue.t()}

  def parse(schema, value)
end
