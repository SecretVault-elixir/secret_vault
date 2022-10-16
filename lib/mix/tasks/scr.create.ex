defmodule Mix.Tasks.Scr.Create do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage

      mix scr.create prod database_password "My Super Secret Password"
  """

  @shortdoc "Create a new secret"

  use Mix.Task

  alias SecretVault.Config
  import SecretVault.TaskHelper

  @default_editor "nano"

  @impl true
  def run(args)

  def run([env, name, data | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- fetch_config(otp_app, env, prefix) do
      SecretVault.put(config, name, data)
    else
      :error ->
        Mix.shell().error("Prefix #{inspect prefix} was not found")

      {:error, {:non_zero_exit_code, code, message}} ->
        Mix.shell().error("Non zero exit code #{code}: #{message}")

      {:error, {:executable_not_found, editor}} ->
        Mix.shell().error("Editor not found: #{editor}")
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.create`."
    Mix.shell().error(msg)
  end
end
