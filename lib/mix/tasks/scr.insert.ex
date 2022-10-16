defmodule Mix.Tasks.Scr.Insert do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage

      mix scr.insert prod database_password "My Super Secret Password"

  ## Config override

  You can override config options by providing command line arguments.

  - `:cipher` - specify a cipher to use;
  - `:priv_path` - path to `priv` directory;
  - `:prefix` - prefix to use (defaults to `default`);
  - `:password` - use a password that's different from the one that's
    configured.
  """

  @shortdoc "Inserts a secret"
  @requirements ["app.config"]

  use Mix.Task

  alias SecretVault.{CLI, Config, ErrorFormatter}

  @impl true
  def run(args)

  def run([env, name, data | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    config_opts =
      Config.available_options()
      |> Enum.map(&{&1, CLI.find_option(rest, nil, "#{&1}")})
      |> Enum.reject(fn {_, value} -> is_nil(value) end)
      |> Keyword.put_new(:priv_path, CLI.priv_path())

    case Config.fetch_from_env(otp_app, env, prefix, config_opts) do
      {:ok, config} -> SecretVault.put(config, name, data)
      {:error, error} -> Mix.shell().error(ErrorFormatter.format(error))
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.create`."
    Mix.shell().error(msg)
  end
end
