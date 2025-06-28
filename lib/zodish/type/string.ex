defmodule Zodish.Type.String do
  @moduledoc ~S"""
  This module describes a Zodish string type.
  """

  import Zodish.Option, only: [merge_opts: 2]

  alias __MODULE__, as: TString

  @type t() :: %TString{
          coerce: boolean(),
          trim: boolean(),
          downcase: boolean(),
          upcase: boolean(),
          exact_length: Zodish.Option.t(non_neg_integer()) | nil,
          min_length: Zodish.Option.t(non_neg_integer()) | nil,
          max_length: Zodish.Option.t(non_neg_integer()) | nil,
          starts_with: Zodish.Option.t(String.t()) | nil,
          ends_with: Zodish.Option.t(String.t()) | nil,
          regex: Zodish.Option.t(Regex.t()) | nil
        }

  defstruct coerce: false,
            trim: false,
            downcase: false,
            upcase: false,
            exact_length: nil,
            min_length: nil,
            max_length: nil,
            starts_with: nil,
            ends_with: nil,
            regex: nil

  def new(opts \\ []) do
    Enum.reduce(opts, %TString{}, fn
      {:coerce, value}, type -> coerce(type, value)
      {:trim, value}, type -> trim(type, value)
      {:downcase, value}, type -> downcase(type, value)
      {:upcase, value}, type -> upcase(type, value)
      {:exact_length, {value, opts}}, type -> exact_length(type, value, opts)
      {:exact_length, value}, type -> exact_length(type, value)
      {:min_length, {value, opts}}, type -> min_length(type, value, opts)
      {:min_length, value}, type -> min_length(type, value)
      {:max_length, {value, opts}}, type -> max_length(type, value, opts)
      {:max_length, value}, type -> max_length(type, value)
      {:starts_with, {value, opts}}, type -> starts_with(type, value, opts)
      {:starts_with, value}, type -> starts_with(type, value)
      {:ends_with, {value, opts}}, type -> ends_with(type, value, opts)
      {:ends_with, value}, type -> ends_with(type, value)
      {:regex, {value, opts}}, type -> regex(type, value, opts)
      {:regex, value}, type -> regex(type, value)
      {key, _}, _ -> raise(ArgumentError, "Unknown option #{inspect(key)} for Zodish.Type.String")
    end)
  end

  def coerce(%TString{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | coerce: value}

  def trim(%TString{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | trim: value}

  def downcase(%TString{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | downcase: value}

  def upcase(%TString{} = type, value \\ true)
      when is_boolean(value),
      do: %{type | upcase: value}

  @opts [error: "Expected string to have exactly {{exact_length | character}}, got {{actual_length | character}}"]
  def exact_length(%TString{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | exact_length: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected string to have at least {{min_length | character}}, got {{actual_length | character}}"]
  def min_length(%TString{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | min_length: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected string to have at most {{max_length | character}}, got {{actual_length | character}}"]
  def max_length(%TString{} = type, value, opts \\ [])
      when is_integer(value) and value >= 0,
      do: %{type | max_length: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected string to start with \"{{prefix}}\", got \"{{value}}\""]
  def starts_with(%TString{} = type, value, opts \\ [])
      when is_binary(value),
      do: %{type | starts_with: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected string to end with \"{{suffix}}\", got \"{{value}}\""]
  def ends_with(%TString{} = type, value, opts \\ [])
      when is_binary(value),
      do: %{type | ends_with: {value, merge_opts(@opts, opts)}}

  @opts [error: "Expected string to match {{pattern}}, got \"{{value}}\""]
  def regex(%TString{} = type, %Regex{} = value, opts \\ []),
    do: %{type | regex: {value, merge_opts(@opts, opts)}}
end

defimpl Zodish.Type, for: Zodish.Type.String do
  import Zodish.Helpers, only: [typeof: 1]
  import Zodish.Issue, only: [issue: 1, issue: 2]

  alias Zodish.Type.String, as: TString

  @impl Zodish.Type
  def parse(%TString{} = type, value) do
    with :ok <- validate_required(value),
         {:ok, value} <- coerce(type, value),
         :ok <- validate_type(value),
         {:ok, value} <- trim(type, value),
         {:ok, value} <- downcase(type, value),
         {:ok, value} <- upcase(type, value),
         :ok <- validate_exact_length(type, value),
         :ok <- validate_min_length(type, value),
         :ok <- validate_max_length(type, value),
         :ok <- validate_starts_with(type, value),
         :ok <- validate_ends_with(type, value),
         :ok <- validate_regex(type, value),
         do: {:ok, value}
  end

  #
  #   PRIVATE
  #

  defp validate_required(nil), do: {:error, issue("Is required")}
  defp validate_required(_), do: :ok

  defp coerce(%{coerce: false}, value), do: {:ok, value}
  defp coerce(%{coerce: true}, <<value::binary>>), do: {:ok, value}
  defp coerce(%{coerce: true}, value) do
    {:ok, to_string(value)}
  rescue
    _ -> {:ok, value}
  end

  defp validate_type(<<_::binary>>), do: :ok
  defp validate_type(value), do: {:error, issue("Expected a string, got #{typeof(value)}")}

  defp trim(%{trim: false}, value), do: {:ok, value}
  defp trim(%{trim: true}, value), do: {:ok, String.trim(value)}

  defp downcase(%{downcase: false}, value), do: {:ok, value}
  defp downcase(%{downcase: true}, value), do: {:ok, String.downcase(value)}

  defp upcase(%{upcase: false}, value), do: {:ok, value}
  defp upcase(%{upcase: true}, value), do: {:ok, String.upcase(value)}

  defp validate_exact_length(%{exact_length: nil}, _), do: :ok
  defp validate_exact_length(%{exact_length: {exact_length, opts}}, value) do
    actual_length = String.length(value)

    case actual_length == exact_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{exact_length: exact_length, actual_length: actual_length})}
    end
  end

  defp validate_min_length(%{min_length: nil}, _), do: :ok
  defp validate_min_length(%{min_length: {min_length, opts}}, value) do
    actual_length = String.length(value)

    case actual_length >= min_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{min_length: min_length, actual_length: actual_length})}
    end
  end

  defp validate_max_length(%{max_length: nil}, _), do: :ok
  defp validate_max_length(%{max_length: {max_length, opts}}, value) do
    actual_length = String.length(value)

    case actual_length <= max_length do
      true -> :ok
      false -> {:error, issue(opts.error, %{max_length: max_length, actual_length: actual_length})}
    end
  end

  defp validate_starts_with(%{starts_with: nil}, _), do: :ok
  defp validate_starts_with(%{starts_with: {prefix, opts}}, value) do
    case String.starts_with?(value, prefix) do
      true -> :ok
      false -> {:error, issue(opts.error, %{prefix: prefix, value: value})}
    end
  end

  defp validate_ends_with(%{ends_with: nil}, _), do: :ok
  defp validate_ends_with(%{ends_with: {suffix, opts}}, value) do
    case String.ends_with?(value, suffix) do
      true -> :ok
      false -> {:error, issue(opts.error, %{suffix: suffix, value: value})}
    end
  end

  defp validate_regex(%{regex: nil}, _), do: :ok
  defp validate_regex(%{regex: {regex, opts}}, value) do
    pattern = String.replace(inspect(regex), ~r/^~r/, "")

    case Regex.match?(regex, value) do
      true -> :ok
      false -> {:error, issue(opts.error, %{pattern: pattern, value: value})}
    end
  end
end
