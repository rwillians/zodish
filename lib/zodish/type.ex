defprotocol Zodish.Type do
  @moduledoc ~S"""
  Protocol for parsing values based on Zodish types.
  """

  @typedoc ~S"""
  A `{mod, fun, args}` tuple pointing to a callback function.
  """
  @type mfa() :: {module(), fun :: atom(), args :: [any()]}

  @doc ~S"""
  Parses a value based on the given Zodish type.
  """
  @spec parse(type :: t(), value :: any()) ::
          {:ok, any()}
          | {:error, String.t()}

  def parse(type, value)
end
