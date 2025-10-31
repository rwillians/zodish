# Zodish

**Zodish** is a schema parser and validator library heavily inspired
by JavaScript's [Zod](https://zod.dev).

```elixir
alias Zodish, as: Z

@schema Z.map(%{
          type:
            Z.enum([:person, :company])
            |> Z.coerce()
            |> Z.optional(default: :person),
          name: Z.string(trim: true, min: 1, max: 100),
          email: Z.email(),
          phone:
            Z.numeric(min: 7, max: 15)
            |> Z.optional()
        })

@type t() :: unquote(Z.to_spec(@schema))

Z.parse(@schema, input)
```

See the full [documentation](https://hexdocs.pm/zodish/Zodish.html) at hexdocs.


## Installation

You can install this package by adding `zodish` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zodish, "~> 0.2"}
  ]
end
```


## Roadmap

Here's a non-exhaustive list of feature that I intend to add in the
near future:

| Feature                                                                                           | Affected Types  | Since  |
| :------------------------------------------------------------------------------------------------ | :-------------: | :----: |
| Normalize options `:*_length` to just `:min`, `:length` and `:max`                                | String, List    | v0.2.0 |
| Make all fields in a `Zodish.Type.Map` or a `Zodish.Type.Struct` optional (`Z.partial/1`)         | Map, Struct     | v0.2.3 |
| Generate type spec from a Zodish type                                                             |                 | v0.2.4 |
| Make it easier to transform field names shown in `Zodish.Issue` messages (e.g. to camelCase)      |                 |        |
| Move generating the final `Zodish.Issue` message to `message/1` function of `Exception`           |                 |        |
| **Dynamicly required fields**                                                                     | Map, Struct     |        |
| Require **at least one of** fields                                                                | Map, Struct     |        |
| Require **at most one of** fields                                                                 | Map, Struct     |        |
| **Mutually inclusive** fields (e.g.: when :a is given, require :b and :c)                         | Map, Struct     |        |
| Add support for internationalization                                                              |                 |        |
| Explicitly allow or forbid **localhost** in `Zodish.Type.URI`                                     | URI             |        |
| Define what ports (enumerated or range) are allowed  in `Zodish.Type.URI`                         | URI             |        |
| Store metadata in Zodish types to be used when generating JSON Schema                             |                 |        |
| Generate JSON Schema from a Zodish type                                                           |                 |        |
| Make it easier to generate docs from Zodish type's metadata (e.g.: describe each field in a map)  |                 |        |
| [?] Introduce a Schema Registry to make it easier to retrieve, reuse reference and manage schemas |                 |        |
