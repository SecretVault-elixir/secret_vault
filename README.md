# SecretVault 🔒

All-in-one solution for storing your Elixir application secrets inside the repository.

## Features

* **Standalone**. No dependencies on external binaries.
* **Secure**. Uses `aes256gcm` cipher by default. Detects weak and similar passwords with `mix scr.audit` task.
* **Developer friendly**. You can use `mix scr.*` tasks to create or
  edit secrets in your favourit editor. Or you can use simple
  coreutils like `mv`, `rm`, `cp`.
* **Easy to use**. Documatation is rich, errors are descriptive and
  tutorials take no more than 5 minutes to read.
* **VCS friendly**. `SecretVault` stores secrets in separate files,
  thus makes it easily to track in VCS.
* **Mix friendly**. `SecretVault` enforces separation of secrets for
  different environments.
* **Extensible**. You can connect your own ciphers, vaults or key
  derivation functions.
* **OTP Compatible**. Uses modern OTP 24 key derivation functions, or
  fallbacks to elixir implementation on lower OTP versions.

## Usage

Check out our [tutorials](https://github.com/spawnfest/secret_vault/blob/main/guides/tutorials/usage.md)
for usage and extension APIs. And build the documenation with `mix docs` since the project has not been
published as a package yet.

## Installation

Just add it to the list of dependencies like

```elixir
def deps do
  [
    {:secret_vault, github: "spawnfest/secret_vault"}
  ]
end
```

## Development

If you want to contribute to the project or just want to test it
localy (not as a dependency), you'll need to create `config/config.exs`
file with following content.

```elixir
config :secret_vault, :secret_vault,
  default: [password: "Some super secret"]
```
