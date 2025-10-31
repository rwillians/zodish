defmodule Zodish.Type.URI do
  alias __MODULE__, as: TUri

  @type t() :: %TUri{
          schemes: [String.t()],
          trailing_slash: :keep | :trim | :enforce
        }

  defstruct schemes: [],
            trailing_slash: :keep

  @doc ~S"""
  Creates a new URI (string) type.
  """
  def new(opts \\ []) do
    Enum.reduce(opts, %TUri{}, fn
      {:schemes, schemes}, type -> schemes(type, schemes)
      {:trailing_slash, value}, type -> format_trailing_slash(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.URI")
    end)
  end

  def schemes(%TUri{} = type, schemes)
      when is_list(schemes),
      do: %TUri{type | schemes: schemes}

  def format_trailing_slash(%TUri{} = type, value)
      when value in [:keep, :trim, :enforce],
      do: %TUri{type | trailing_slash: value}
end

defimpl Zodish.Type, for: Zodish.Type.URI do
  import Zodish.Issue, only: [issue: 1]

  alias Zodish.Type.URI, as: TUri

  @impl Zodish.Type
  def parse(%TUri{} = type, value) do
    with :ok <- validate_required(value),
         :ok <- validate_type(type, value),
         value <- format_trailing_slash(type, value),
         do: {:ok, value}
  end

  @impl Zodish.Type
  def to_spec(%TUri{}), do: quote(do: String.t())

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
    end
  end

  defp format_trailing_slash(%TUri{trailing_slash: :keep}, uri), do: uri
  defp format_trailing_slash(%TUri{trailing_slash: :trim}, uri) do
    %URI{} = uri = URI.parse(uri)

    uri = %URI{
      uri
      | path: if(is_nil(uri.path), do: nil, else: String.trim_trailing(uri.path || "", "/"))
    }

    URI.to_string(uri)
  end
  defp format_trailing_slash(%TUri{trailing_slash: :enforce}, uri) do
    %URI{} = uri = URI.parse(uri)

    uri = %URI{
      uri
      | path: if(is_nil(uri.path), do: nil, else: String.trim_trailing(uri.path, "/") <> "/")
    }

    URI.to_string(uri)
  end
end
