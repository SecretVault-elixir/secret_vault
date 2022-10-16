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

  use Mix.Task

  alias SecretVault.TaskHelper

  @impl true
  def run(args)

  def run([env, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = TaskHelper.find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- TaskHelper.fetch_config(otp_app, env, prefix),
         {:ok, data} <- SecretVault.fetch(config, name) do
      Mix.shell().info(data)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        Mix.shell().error("No configuration for prefix #{prefix} found")

      {:error, :secret_not_found} ->
        message = "Secret #{name} not found in environment #{env}"
        Mix.shell().error(message)

      {:error, :unknown_environment} ->
        Mix.shell().error("Environment #{env} does not exist")
    end
  end

  def run([environment | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = TaskHelper.find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- TaskHelper.fetch_config(otp_app, environment, prefix),
         {:ok, names} <- SecretVault.list(config) do
      message = Enum.join(names, "\n")
      Mix.shell().info(message)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)

      {:error, :unknown_prefix} ->
        message =
          "Prefix #{inspect(prefix)} for environment #{inspect(environment)}" <>
            " does not exist"

        Mix.shell().error(message)
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.show`."
    Mix.shell().error(msg)
  end
end
