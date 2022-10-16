defmodule Mix.Tasks.Scr.Show do
  @moduledoc """
  Shows an existing secret in specified environment and under
  specified name.

  If the name of a secret is not provided, it lists all the existing
  secrets.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage

  To show the secret use

      mix scr.show prod database_url

  If you want to list all the available secrets for the environment,
  you can run

      mix scr.show prod

  """

  @shortdoc "Show an existing secret or list all the ones"
  @requirements ["app.config"]

  use Mix.Task

  alias SecretVault.{CLI, Config, ErrorFormatter}

  @impl true
  def run(args)

  def run([env, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    config_opts =
      Config.available_options()
      |> Enum.map(&{&1, CLI.find_option(rest, nil, "#{&1}")})
      |> Enum.reject(fn {_, value} -> is_nil(value) end)

    with {:ok, config} <-
           Config.fetch_from_env(otp_app, env, prefix, config_opts),
         {:ok, data} <- SecretVault.fetch(config, name) do
      Mix.shell().info(data)
    else
      {:error, error} -> Mix.shell().error(ErrorFormatter.format(error))
    end
  end

  def run([environment | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- Config.fetch_from_env(otp_app, environment, prefix),
         {:ok, names} <- SecretVault.list(config) do
      message = Enum.join(names, "\n")
      Mix.shell().info(message)
    else
      {:error, error} -> Mix.shell().error(ErrorFormatter.format(error))
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.show`."
    Mix.shell().error(msg)
  end
end
