# SecretVault

All-in-one solution for storing your Elixir application secrets inside the repository.

## Features

* **Standalone**. No dependencies on external binaries.
* **Secure**. Uses `aes256gcm` cipher by default. Performs audit to detect weak and duplicate passwords using `mix scr.audit` task.
* **Developer friendly**. You can use `mix scr.*` tasks to create or edit secrets in your favourit editor. Or you can use simple coreutils like `mv`, `rm`, `cp`.
* **Easy to use**. Documatation is rich, errors are descriptive and tutorials take no more than 5 minutes to read.
* **VCS friendly**. `SecretVault` stores secrets in separate files, thus makes it easily to track in VCS.
* **Mix friendly**. `SecretVault` enforces you to separate secrets for different environments.
* **Extensible**. You can connect your own ciphers, vaults or key derivation functions.
* **OTP Compatible**. Uses modern OTP 24 key derivation functions, or fallbacks to elixir implementation on lower OTP versions.

## Usage

Check out our tutorials for usage and extensions API here: https://hexdocs.pm/secret_vault

## Installation

```elixir
def deps do
  [
    {:secret_vault, github: "spawnfest/secret_vault"}
  ]
end
```

## Development

If you want to contribute to the project or just want to test it
localy (not via dependencies), you need to create `config/config.exs`
file with following content

```elixir
config :secret_vault, :secret_vault, default: []
```
