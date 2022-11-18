defmodule Mix.Tasks.Scr.Create do
  @moduledoc """
  Creates a new secret in the specified environment and under
  the specified name using your preffered editor.

  It uses configuration of the current application to retrieve the
  keys and other options.

  ## Usage

      mix scr.create prod database_url

  ## Config override

  You can override config options by providing command line arguments.

  - `:cipher` - specify a cipher module to use;
  - `:priv_path` - path to `priv` directory;
  - `:prefix` - prefix to use (defaults to `default`);
  - `:password` - use a password that's different from the one that's
    configured.
  """

  @shortdoc "Create a new secret"
  @requirements ["app.config"]

  use Mix.Task

  alias SecretVault.{CLI, Config, Editor, ErrorFormatter}

  @impl true
  def run(args)

  def run([environment, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    config_opts =
      Config.available_options()
      |> Enum.map(&{&1, CLI.find_option(rest, nil, "#{&1}")})
      |> Enum.reject(fn {_, value} -> is_nil(value) end)

    with {:ok, config} <-
           Config.fetch_from_env(otp_app, environment, prefix, config_opts),
         :ok <- ensure_secret_doesn_not_exist(config, name),
         {:ok, data} <- Editor.open_new_file() do
      SecretVault.put(config, name, data)
    else
      {:error, error} -> Mix.shell().error(ErrorFormatter.format(error))
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.create`."
    Mix.shell().error(msg)
  end

  defp ensure_secret_doesn_not_exist(config, name) do
    if SecretVault.exists?(config, name) do
      {:error, {:secret_already_exists, name}}
    else
      :ok
    end
  end
end
