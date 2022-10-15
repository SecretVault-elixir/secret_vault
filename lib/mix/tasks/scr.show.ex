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

  alias SecretVault.ConfigHelper

  @impl true
  def run(args)

  def run([environment, name | rest]) do
    key = ""

    otp_app = Mix.Project.config()[:app]
    prefix = find_prefix(rest)

    with {:ok, config} <- ConfigHelper.fetch_config(otp_app, prefix),
         {:ok, data} <- SecretVault.fetch_secret(config, key, environment, name) do
      Mix.shell().info(data)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        Mix.shell().error("No configuration for prefix #{prefix} found")

      {:error, :no_vaults_configured} ->
        Mix.shell().error("No vaults configured for the app")

      {:error, :no_prefix_provided_when_multiple_configured} ->
        message =
          "No prefix provided when multiple configured. " <>
            "Use --prefix option to specify the prefix"

        Mix.shell().error(message)

      {:error, :secret_not_found} ->
        message = "Secret #{name} not found in environment #{environment}"
        Mix.shell().error(message)

      {:error, :unknown_environment} ->
        Mix.shell().error("Environment #{environment} does not exist")
    end
  end

  def run([environment | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = find_prefix(rest)

    with {:ok, config} <- ConfigHelper.fetch_config(otp_app, prefix),
         {:ok, secrets} <- SecretVault.list_secrets(config, environment) do
      message = Enum.join(secrets, "\n")
      Mix.shell().info(message)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        Mix.shell().error("No configuration for prefix #{prefix} found")

      {:error, :no_vaults_configured} ->
        Mix.shell().error("No vaults configured for the app")

      {:error, :no_prefix_provided_when_multiple_configured} ->
        message =
          "No prefix provided when multiple configured. " <>
            "Use --prefix option to specify the prefix"

        Mix.shell().error(message)

      {:error, :unknown_environment} ->
        Mix.shell().error("Environment #{environment} does not exist")
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.show`."
    Mix.shell().error(msg)
  end

  defp find_prefix(["--prefix", prefix | _rest]) do
    prefix
  end

  defp find_prefix([_ | rest]) do
    find_prefix(rest)
  end

  defp find_prefix([]) do
    nil
  end
end
