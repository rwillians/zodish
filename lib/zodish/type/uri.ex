defmodule Zodish.Type.URI do
  alias __MODULE__, as: TUri

  @typedoc false
  @type t() :: %TUri{
          schemes: [String.t()],
          trim_trailing_slash: boolean()
        }

  defstruct schemes: [],
            trim_trailing_slash: false

  @doc false
  def new(opts \\ []) do
    Enum.reduce(opts, %TUri{}, fn
      {:schemes, schemes}, type -> schemes(type, schemes)
      {:trim_trailing_slash, value}, type -> trim_trailing_slash(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.URI")
    end)
  end

  @doc false
  def schemes(%TUri{} = type, schemes)
      when is_list(schemes),
      do: %TUri{type | schemes: schemes}

  @doc false
  def trim_trailing_slash(%TUri{} = type, value \\ true)
      when is_boolean(value),
      do: %TUri{type | trim_trailing_slash: value}
end

defimpl Zodish.Type, for: Zodish.Type.URI do
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.URI, as: TUri

  @impl Zodish.Type
  def infer(%TUri{}) do
    quote(do: String.t())
  end

  @impl Zodish.Type
  def parse(%TUri{} = type, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(type, value),
         value <- trim_trailing_slash(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("is required")}
  defp validate_required(<<>>), do: {:error, issue("is required")}
  defp validate_required(_), do: :ok

  defp validate_type(%TUri{} = type, value) do
    case {type.schemes, URI.parse(value)} do
      {[], %URI{}} ->
        :ok

      {schemes, %URI{scheme: scheme}} ->
        if scheme in schemes,
           do: :ok,
           else: {:error, issue("scheme not allowed")}

      {_, _} ->
        {:error, issue("is invalid")}
    end
  end

  defp trim_trailing_slash(%TUri{trim_trailing_slash: false}, uri), do: uri
  defp trim_trailing_slash(_, uri), do: String.trim_trailing(uri, "/")
end
