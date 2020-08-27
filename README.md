# Mobius

An Elixir library for Discord bots

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mobius` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mobius, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mobius](https://hexdocs.pm/mobius).

## Missing features

- [ ] Rewrite the demo_bot so we can run it from iex
- [ ] System test which starts a real bot and tries as many endpoints as possible
- [ ] Intents
- [ ] Implement all missing api endpoints
- [ ] Implement a cache of objects
- [ ] Sanitize event data
- [ ] Struct-ify data
- [ ] Updating intents without closing all shards at once
