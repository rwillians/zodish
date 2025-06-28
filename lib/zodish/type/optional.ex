defmodule Zodish.Type.Optional do
  @moduledoc ~S"""
  Makes a given type optional, where you can also define a default
  value to be used when the value is `nil`.
  """

  alias __MODULE__, as: TOptional

  @type t() :: t(Zodish.Type.t())
  @type t(inner_type) :: %TOptional{
          inner_type: inner_type,
          default: inner_type | (-> inner_type) | nil
        }

  defstruct inner_type: nil,
            default: nil

  def new(%_{} = inner_type, opts \\ []) do
    Enum.reduce(opts, %TOptional{inner_type: inner_type}, fn
      {:default, value}, type -> default(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Optional")
    end)
  end

  def default(%TOptional{} = type, value) when is_function(value, 0), do: %{type | default: value}

  def default(%TOptional{} = type, value) do
    case Zodish.Type.parse(type.inner_type, value) do
      {:ok, value} -> %{type | default: value}
      {:error, _} -> raise(ArgumentError, "The default value must satisfy the inner type of Zodish.Type.Optional")
    end
  end
end

defimpl Zodish.Type, for: Zodish.Type.Optional do
  alias Zodish.Type.Optional, as: TOptional

  @impl Zodish.Type
  def parse(%TOptional{default: nil}, nil), do: {:ok, nil}
  def parse(%TOptional{} = type, nil) do
    with {:ok, value} <- Zodish.Type.parse(type.inner_type, resolve(type.default)),
         do: {:ok, value}
  end
  def parse(%TOptional{} = type, value), do: Zodish.Type.parse(type.inner_type, value)

  #
  #   PRIVATE
  #

  defp resolve(fun) when is_function(fun), do: apply(fun, [])
  defp resolve(value), do: value
end
