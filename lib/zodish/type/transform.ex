defmodule Zodish.Type.Transform do
  alias __MODULE__, as: Transform

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %Transform{
          inner_type: inner_type,
          fun: (any() -> any())
        }

  defstruct inner_type: nil,
            fun: nil

  @doc false
  def new(%_{} = inner_type, fun)
      when is_function(fun, 1),
      do: %Transform{inner_type: inner_type, fun: fun}
end

defimpl Zodish.Type, for: Zodish.Type.Transform do
  alias Zodish.Type.Transform, as: Transform

  @impl Zodish.Type
  def infer(%Transform{}) do
    quote(do: term())
  end

  @impl Zodish.Type
  def parse(%Transform{} = type, value) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, value),
         do: {:ok, apply(type.fun, [value])}
  end
end
