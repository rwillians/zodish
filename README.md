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
            Z.string(regex: {~r/^\+\d{7,15}/, error: "invalid phone number"})
            |> Z.optional()
        })

def parse(input) do
  Z.parse(@schema, input)
end
```

See the full [documentation](https://hexdocs.pm/zodish) at hexdocs.


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

1. ***At least one of*** fields for `Zodish.Type.Map` and `Zodish.Type.Struct`;
2. ***At most one of*** fields for `Zodish.Type.Map` and `Zodish.Type.Struct`;
3. ***Dynamic required fields*** for `Zodish.Type.Map` and `Zodish.Type.Struct`;
4. ...
