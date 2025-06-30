defmodule Zodish.Type.Uuid do
  alias __MODULE__, as: TUuid

  @type version() :: :any | :v1 | :v2 | :v3 | :v4 | :v5 | :v6 | :v7 | :v8

  @type t() :: %TUuid{
          version: version()
        }

  defstruct version: :any

  def new(version \\ :any)
      when version in [:any, :v1, :v2, :v3, :v4, :v5, :v6, :v7, :v8],
      do: %TUuid{version: version}
end

defimpl Zodish.Type, for: Zodish.Type.Uuid do
  alias Zodish.Type.String, as: TString
  alias Zodish.Type.Uuid, as: TUuid

  @impl Zodish.Type
  def parse(%TUuid{} = schema, value) do
    regex = regex_for(schema.version)

    TString.new()
    |> TString.exact_length(36)
    |> TString.regex(regex, error: "Invalid UUID")
    |> Zodish.Type.parse(value)
  end

  #
  #   PRIVATE
  #

  # Source: https://github.com/colinhacks/zod/blob/6176dcb570186c4945223fa83bcf3221cbfa1af5/packages/zod/src/v4/core/regexes.ts#L22-L28
  defp regex_for(:any), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000)$/
  defp regex_for(:v1), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-1[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v2), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-2[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v3), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-3[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v4), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v5), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-5[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v6), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-6[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v7), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
  defp regex_for(:v8), do: ~r/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-8[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/
end
