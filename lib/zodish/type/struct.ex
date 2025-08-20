defmodule Zodish.Type.Struct do
  import Zodish.Helpers, only: [take_sorted: 2, to_mod_name: 1]

  alias __MODULE__, as: TStruct

  @type shape() :: %{
          required(atom()) => Zodish.Type.t()
        }

  @type t() :: %TStruct{
          coerce: boolean(),
          module: module(),
          mode: :strict | :strip,
          shape: shape()
        }

  defstruct coerce: false,
            module: nil,
            mode: :strict,
            shape: %{}

  @doc false
  def new([{_, _} | _] = opts) do
    relevant = take_sorted(opts, [:module, :mode, :shape])
    other = opts -- relevant

    #      ↓ makes sure :shape comes after :module
    opts = relevant ++ other
    #                       ↑ we'll get an error if a unsupported key is given

    Enum.reduce(opts, %TStruct{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:module, mod}, type -> module(type, mod)
      {:mode, :strip}, type -> strip(type)
      {:mode, :strict}, type -> strict(type)
      {:shape, shape}, type -> shape(type, shape)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.Struct")
    end)
  end

  @doc false
  def new(module, %{} = shape) when is_atom(module), do: new(module: module, mode: :strict, shape: shape)
  def new([{_, _} | _] = opts, %{} = shape), do: new(opts ++ [shape: shape])

  @doc false
  def coerce(%TStruct{} = type, value \\ true)
      when is_boolean(value),
      do: %TStruct{type | coerce: value}

  @doc false
  def module(%TStruct{} = type, mod)
      when is_atom(mod),
      do: %TStruct{type | module: mod}

  @doc false
  def strip(%TStruct{} = type), do: %TStruct{type | mode: :strip}

  @doc false
  def strict(%TStruct{} = type), do: %TStruct{type | mode: :strict}

  @doc false
  def shape(%TStruct{} = type, %{} = shape)
      when is_non_struct_map(shape) and map_size(shape) > 0 do
    struct_keys = Map.keys(struct!(type.module, []))
    shape_keys = Map.keys(shape)

    non_existent_keys = shape_keys -- struct_keys
    # ↑ keys defined in the shape that do not exist in the struct

    for key <- non_existent_keys do
      raise ArgumentError, "The shape key :#{key} doesn't exist in struct #{to_mod_name(type.module)}"
    end

    %TStruct{type | shape: shape}
  end

  def shape(%TStruct{}, %_{}), do: raise(ArgumentError, "Shape cannot be a struct")
  def shape(%TStruct{}, %{}), do: raise(ArgumentError, "Shape cannot be empty")
end

defimpl Zodish.Type, for: Zodish.Type.Struct do
  import Zodish.Helpers, only: [to_mod_name: 1]
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.Map, as: TMap
  alias Zodish.Type.Struct, as: TStruct

  @impl Zodish.Type
  def infer(%TStruct{module: mod}) do
    quote(do: %unquote(mod){})
  end

  @impl Zodish.Type
  def parse(%TStruct{module: module} = type, %module{} = value), do: parse(type, Map.from_struct(value))
  def parse(%TStruct{} = type, %module{}), do: {:error, issue("expected a struct of type #{to_mod_name(type.module)}, got struct of #{to_mod_name(module)}")}
  def parse(%TStruct{} = type, value) do
    maptype = TMap.new(coerce: type.coerce, mode: type.mode, shape: type.shape)

    with {:ok, parsed} <- Zodish.Type.parse(maptype, value),
         do: {:ok, struct!(type.module, parsed)}
  end
end
