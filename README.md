# SecretVault

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `secret_vault` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:secret_vault, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/secret_vault>.

## Development

If you want to contribute to the project or just want to test it
localy (not via dependencies), you need to create `config/config.exs`
file with following content

```elixir
config :secret_vault, :secret_vault,
  default: []
```
