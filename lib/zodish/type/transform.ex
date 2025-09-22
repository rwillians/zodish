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

  def new(%_{} = inner_type, {mod, fun, args})
      when is_atom(mod) and is_atom(fun) and is_list(args),
      do: %Transform{inner_type: inner_type, fun: {mod, fun, args}}
end

defimpl Zodish.Type, for: Zodish.Type.Transform do
  alias Zodish.Type.Transform, as: Transform

  @impl Zodish.Type
  def parse(%Transform{} = type, value) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, value),
         do: {:ok, transform(type.fun, value)}
  end

  defp transform({mod, fun, args}, value), do: apply(mod, fun, [value] ++ args)
  defp transform(fun, value) when is_function(fun, 1), do: apply(fun, [value])
end
