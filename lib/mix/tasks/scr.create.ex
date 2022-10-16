defmodule Mix.Tasks.Scr.Create do
  @moduledoc """
  Creates a new secret in specified environment and under specified
  name using your preffered editor.

  It uses configuration of current application to retrieve keys and
  other options.

  ## Usage
      mix scr.create prod database_url
  """

  @shortdoc "Create a new secret"
  @requirements ["app.config"]

  use Mix.Task

  alias SecretVault.{CLI, Config, Editor}

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
      {:error, :secret_already_exists} ->
        Mix.shell().error("Secret with name #{name} already exists")

      {:error, {:no_configuration_for_prefix, prefix}} ->
        message = "No configuration for prefix #{inspect(prefix)} found"
        Mix.shell().error(message)

      {:error, {:no_configuration_for_app, otp_app}} ->
        Mix.shell().error("No configuration for otp_app #{otp_app} found")

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

  defp ensure_secret_doesn_not_exist(config, name) do
    if SecretVault.exists?(config, name) do
      {:error, :secret_already_exists}
    else
      :ok
    end
  end
end
