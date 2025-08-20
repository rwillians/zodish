defmodule Zodish.Type.Email do
  alias __MODULE__, as: TEmail

  @type ruleset() :: :gmail | :html5 | :rfc5322 | :unicode

  @type t() :: %TEmail{
          ruleset: ruleset()
        }

  defstruct ruleset: :gmail

  @doc false
  def new(opts \\ []) do
    Enum.reduce(opts, %TEmail{}, fn
      {:ruleset, value}, schema -> ruleset(schema, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)}")
    end)
  end

  @doc false
  def ruleset(%TEmail{} = schema, value)
      when value in [:gmail, :html5, :rfc5322, :unicode],
      do: %{schema | ruleset: value}
end

defimpl Zodish.Type, for: Zodish.Type.Email do
  alias Zodish.Type.Email, as: TEmail
  alias Zodish.Type.String, as: TString

  @impl Zodish.Type
  def parse(%TEmail{} = schema, value) do
    regex = regex_for(schema.ruleset)

    TString.new()
    |> TString.min_length(1, error: "cannot be empty")
    |> TString.regex(regex, error: "invalid email address")
    |> Zodish.Type.parse(value)
  end

  #
  #   PRIVATE
  #

  # Source: https://github.com/colinhacks/zod/blob/6176dcb570186c4945223fa83bcf3221cbfa1af5/packages/zod/src/v4/core/regexes.ts#L33-L50
  defp regex_for(:gmail), do: ~r/^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$/
  defp regex_for(:html5), do: ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  defp regex_for(:rfc5322), do: ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  defp regex_for(:unicode), do: ~r/^[^\s@"]{1,64}@[^\s@]{1,255}$/u
end
