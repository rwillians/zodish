defmodule Zodish.Type.Struct do
  import Zodish.Helpers, only: [to_mod_name: 1]

  alias __MODULE__, as: TStruct

  @type shape() :: %{
          required(atom()) => Zodish.Type.t()
        }

  @type t() :: %TStruct{
          shape: shape()
        }

  defstruct mod: nil,
            shape: %{}

  def new(module, %{} = shape)
      when is_atom(module) and is_non_struct_map(shape) and map_size(shape) == 0,
      do: raise(ArgumentError, "Shape cannot be empty")

  def new(module, %{} = shape)
      when is_atom(module) and is_non_struct_map(shape) and map_size(shape) > 0 do
    struct_keys_index =
      struct!(module, [])
      |> Map.keys()
      |> Enum.map(&{&1, true})
      |> Enum.into(%{})

    for {key, _} <- shape,
        not Map.has_key?(struct_keys_index, key),
        do: raise(ArgumentError, "The shape key #{inspect(key)} doesn't exist in struct #{to_mod_name(module)}")

    %TStruct{mod: module, shape: shape}
  end
end

defimpl Zodish.Type, for: Zodish.Type.Struct do
  import Zodish.Helpers, only: [to_mod_name: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Map, as: TMap
  alias Zodish.Type.Struct, as: TStruct

  @impl Zodish.Type
  def parse(%TStruct{mod: mod} = type, %mod{} = value), do: parse(type, Map.from_struct(value))
  def parse(%TStruct{} = type, %mod{}), do: {:error, issue("Expected a struct of type #{to_mod_name(type.mod)}, got struct of #{to_mod_name(mod)}")}
  def parse(%TStruct{} = type, value) do
    maptype = TMap.new(:strict, type.shape)

    with {:ok, parsed} <- Zodish.Type.parse(maptype, value),
         do: {:ok, struct!(type.mod, parsed)}
  end
end
