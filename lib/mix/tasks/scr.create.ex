defmodule Mix.Tasks.Scr.Create do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name.

  It uses configuration of current application to retrieve keys and
  so on.

  ## Usage
      mix scr.create prod database_url
  """

  @shortdoc "Create a new secret"

  use Mix.Task

  alias SecretVault.{EditorHelper, TaskHelper}

  @impl true
  def run(args)

  def run([environment, name | rest]) do
    otp_app = Mix.Project.config()[:app]
    prefix = TaskHelper.find_option(rest, "p", "prefix") || "default"

    with {:ok, config} <- TaskHelper.fetch_config(otp_app, environment, prefix),
         {:ok, data} <- EditorHelper.open_new_file() do
      SecretVault.put(config, name, data)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)

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
