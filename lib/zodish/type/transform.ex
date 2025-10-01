defmodule Zodish.Type.Transform do
  alias __MODULE__, as: Transform

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %Transform{
          inner_type: inner_type,
          fun: (any() -> any()) | mfa()
        }

  defstruct inner_type: nil,
            fun: nil

  @doc false
  def new(%_{} = inner_type, fun)
      when is_function(fun, 1),
      do: %Transform{inner_type: inner_type, fun: fun}

  def new(%_{} = inner_type, {m, f, a})
      when is_atom(m) and is_atom(f) and is_list(a),
      do: %Transform{inner_type: inner_type, fun: {m, f, a}}
end

defimpl Zodish.Type, for: Zodish.Type.Transform do
  alias Zodish.Type.Transform, as: Transform

  @impl Zodish.Type
  def parse(%Transform{} = type, value) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, value),
         do: {:ok, transform(type.fun, value)}
  end

  defp transform({m, f, a}, value), do: apply(m, f, [value | a])
  defp transform(fun, value) when is_function(fun, 1), do: apply(fun, [value])
end
