defmodule Zodish.Type.Refine do
  alias __MODULE__, as: Refine

  @type refine_fun() :: (any() -> boolean())

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %Refine{
          inner_type: inner_type,
          fun: refine_fun(),
          error: String.t()
        }

  defstruct inner_type: nil,
            fun: nil,
            error: "is invalid"

  @doc false
  def new(%_{} = inner_type, fun, opts \\ [])
      when is_function(fun, 1) and is_list(opts) do
    type = %Refine{
      inner_type: inner_type,
      fun: fun,
    }

    Enum.reduce(opts, type, fn
      {:error, value}, type -> error(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Refine")
    end)
  end

  @doc false
  def error(%Refine{} = type, <<message::binary>>), do: %{type | error: message}
end

defimpl Zodish.Type, for: Zodish.Type.Refine do
  import Zodish.Issue, only: [issue: 1, parse_score: 1]

  alias Zodish.Type.Refine, as: Refine

  @impl Zodish.Type
  def parse(%Refine{} = type, value) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, value),
         {:ok, value} <- refine(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp refine(%Refine{fun: fun} = type, value) do
    case apply(fun, [value]) do
      true -> {:ok, value}
      false -> {:error, %{issue(type.error) | parse_score: parse_score(value)}}
    end
  end
end
