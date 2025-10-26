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


## Next up

Here's a non-exhaustive list of feature that I intend to add in the
near future:

- [ ] ***At least one of*** fields for `Zodish.Type.Map` and `Zodish.Type.Struct`;
- [ ] ***At most one of*** fields for `Zodish.Type.Map` and `Zodish.Type.Struct`;
- [ ] ***Dynamic required fields*** for `Zodish.Type.Map` and `Zodish.Type.Struct`;
- [ ] Explicitly allow or forbid **localhost** on `Zodish.Type.URL`;
- [ ] Define what ports (enumerated or range) are allowed on `Zodish.Type.URL`;
- [x] Normalize `:min_length`, `:exact_length` and `:max_length` on
      `Zodish.Type.String` and `Zodish.Type.List` to `:min`, `:length`
      and `:max` respectively;
- [ ] Add support for internationalized error messages;
- [ ] Make it possible to transform field names shown in `Zodish.Issue` messages;
