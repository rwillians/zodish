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
          name: Z.string(trim: true, min_length: 1, max_length: 100),
          email: Z.email(),
          phone:
            Z.string(regex: {~r/^\+\d{7,15}$/, error: "invalid phone number"})
            |> Z.optional()
        })

def parse(input) do
  Z.parse(@schema, input)
end
```

See the full [documentation](https://hexdocs.pm/zodish/Zodish.html) at hexdocs.


## Installation

You can install this package by adding `zodish` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zodish, "~> 0.1.0"}
  ]
end
```


## Roadmap / Next up

Here's a non-exhaustive list of feature that I intend to add in the
near future:

| Priority | Feature                                                                                          | Since  |
| -------: | :----------------------------------------------------------------------------------------------- | :----: |
|        0 | Normalize options `:*_length` to just `:min`, `:length` and `:max` (String and List types)       | v0.2.0 |
|        0 | Make it possible to transform field names shown in `Zodish.Issue` messages (e.g. to camelCase)   |        |
|        1 | Add support for internationalization                                                             |        |
|        1 | ***Dynamicly required fields***  (Map and Struct types)                                          |        |
|        2 | Require ***at least one of*** fields (Map and Struct types)                                      |        |
|        2 | Require ***at most one of*** fields (Map and Struct types)                                       |        |
|        3 | Explicitly allow or forbid **localhost** (on URI type)                                           |        |
|        3 | Define what ports (enumerated or range) are allowed (on URI type)                                |        |
|        3 | Generate JSON Schema from a Zodish schema                                                        |        |
|        3 | Introduce a Schema Registry to make it easier to retrieve, reuse reference and manage schemas    |        |

Legend:

| Priority | Description |
| -------: | :---------- |
|        0 | Very high   |
|        1 | High        |
|        2 | So so       |
|        3 | Low         |
