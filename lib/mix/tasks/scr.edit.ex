defmodule Mix.Tasks.Scr.Edit do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage

      mix scr.edit prod database_url
  """

  @shortdoc "Create a new secret"

  use Mix.Task

  alias SecretVault.{Config, Editor, TaskHelper}

  @impl true
  def run(args)

  def run([environment, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = TaskHelper.find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- Config.fetch_from_env(otp_app, environment, prefix),
         {:ok, original_data} <- SecretVault.fetch(config, name),
         {:ok, updated_data} <- Editor.open_file_on_edit(original_data) do
      SecretVault.put(config, name, updated_data)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)

      {:error, {:non_zero_exit_code, code}} ->
        Mix.shell().error("Non zero exit code #{code}")

      {:error, {:executable_not_found, editor}} ->
        Mix.shell().error("Editor not found: #{editor}")

      {:error, :secret_not_found} ->
        message =
          "Secret #{name} not found in environment #{inspect(environment)}"

        Mix.shell().error(message)

      {:error, :unknown_prefix} ->
        message =
          "Prefix #{inspect(prefix)} for environment #{inspect(environment)}" <>
            " does not exist"

        Mix.shell().error(message)
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.edit`."
    Mix.shell().error(msg)
  end
end
