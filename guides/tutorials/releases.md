# Mix release integration

`mix release` allows user to make an aritfact of the application to ease further distribution.
This leads to several limitations which can be solved using SecretVault.

## Release configuration

Specify `secret_vault` or your stub application for secrets as permanent in `mix.exs`. For example:
```elixir
releases: [
  demo: [
    applications: [
      # For plain apps
      secret_vault: :permanent,

      # Or for stub apps (like in umbrella tutorial)
      secret_vault_stub: :permanent
    ]
  ]
]
```

## Runtime configuration

Building Elixir application in releases, generates `sys.config` from compile time configuration, so
default approach with password in `config.exs` will have the password in plain form in `sys.config`.
To avoid this, you must specify secret to be lazyly fetched in runtime.

So, in your `config/config.exs`:
```elixir
config :my_app, :secret_vault,
  default: [password: {System, :get_env, "VARIABLE_WITH_PASSWORD"}]
```

And in your `config/runtime.exs`:
```elixir
import SecretVault, only: [runtime_secret: 2]

config :my_app, :database_password, runtime_secret(:my_app, "database_password")
```
