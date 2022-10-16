# Usage tutorial

This is a 5 minutes tutorial about usage of `SecretVault` which shows how to install, configure `SecretVault` and create,
delete, edit and access secrets in `Runtime`.

### Install

Just add it into your deps like
```
defp deps do
  [
    {:secret_vault, github: "spawnfest/secret_vault"}
  ]
end
```

### Configure

Configuration is straightforward. Minimal configuration would look like this:
```
import Config

config :my_app, :secret_vault,
  default: [password: System.fetch_env!("SECRET_VAULT_PASSWORD")]
```

Here `default` is a name of a default prefix. Prefixes works kinda like namespaces for secrets. You can
provide options other than `password`, to see a full list of those check out the `SecretVault.Config.new/2` documentation.

> Note:
> that each `MIX_ENV` will have it's own separate vault, so don't use prefixes to separate envs.

### Create secrets

To create a secret during development you can use one of many secret creating tasks available.
But do not forget to provide the enviroment variable with the password which we specified above.

For example,
```sh
$ export SECRET_VAULT_PASSWORD="password" # Don't forget to change the password value
$ echo "My Super Secret Password" | mix scr.insert dev database_password
```

Or, to write a password in your favourite editor, use
```sh
$ mix scr.create dev database_password
```

Here `dev` defines the `MIX_ENV` for which you'd like to create a secret. And `database_password` is a name of secret.
These exact commands will create a secret in `priv/dev/default/database_password.vault_secret`. Each secret is written onto it's own
file in vault directory in `priv`. This plays nice with version control systems and simplifies the user interface.

> Note:
> Each secret is written into it's own file with `.vault_secret` extension. Therefore, secrets' names must be suitable file names.

### Manipulate secrets

To edit already created secrets, one can use `mix scr.insert` and `mix scr.edit` commands. To delete, rename or copy secrets, one
can use regular coreutils like `mv`, `cp`, `rm`, since each secret is placed under the corresponding directory in `priv`. Usually
the path is `priv/$MIX_ENV/$PREFIX/${SECRET_NAME}.vault_secret`.

For example, to delete secret create in previous step, one could write
```sh
$ rm priv/dev/default/database_password.vault_secret
```

### Access secrets

To access and use secrets from `Elixir` application, one first need to retrieve the vault configuration. Then, it is recommended
to place the secrets into some runtime storage (like `persistent_term`, for example).

So, regular workflow would look like
```
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    ...
    {:ok, config} = SecretVault.Config.fetch_from_env(:my_app)
    SecretVault.Storage.to_persistent_term(config)
  end
end
```

This will create config from configuration of your application and put all decrypted passwords in the `persistent_term`.
See `SecretVault.Config` and `SecretVault.Storage` for more options.

If you want to have you options in application env you can specify this in `config.exs`

```
import Config

config :my_app, :secret_vault,
  default: [password: System.fetch_env!("SECRET_VAULT_PASSWORD")]

{:ok, config} = SecretVault.Config.fetch_from_env(:my_app)
SecretVault.Storage.to_application_env(config)
```

### Release

There is no special behaviour for releases. Just `mix release` and use.
