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
            error: "Is invalid"

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

  #
  #   PRIVATE
  #

  defp error(%Refine{} = type, <<value::binary>>), do: %{type | error: value}
end

defimpl Zodish.Type, for: Zodish.Type.Refine do
  import Zodish.Issue, only: [issue: 1, parse_score: 1]

  alias Zodish.Type.Refine, as: TRefine

  @impl Zodish.Type
  def parse(%TRefine{} = type, value) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, value),
         {:ok, value} <- refine(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp refine(%TRefine{fun: fun} = type, value) do
    case apply(fun, [value]) do
      true -> {:ok, value}
      false -> {:error, %{issue(type.error) | parse_score: parse_score(value)}}
    end
  end
end
