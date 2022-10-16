defmodule Mix.Tasks.Scr.Insert do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage

      mix scr.insert prod database_password "My Super Secret Password"
  """

  @shortdoc "Inserts a secret"

  use Mix.Task

  alias SecretVault.{CLI, Config}

  @impl true
  def run(args)

  def run([env, name, data | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = CLI.find_option(rest, "p", "prefix") || "default"

    case Config.fetch_from_env(otp_app, env, prefix) do
      {:ok, config} ->
        SecretVault.put(config, name, data)

      :error ->
        Mix.shell().error("No configuration found")

      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.create`."
    Mix.shell().error(msg)
  end
end
