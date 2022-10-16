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

  import SecretVault.TaskHelper

  @impl true
  def run(args)

  def run([env, name | rest]) do
    editor = find_editor()

    otp_app = Mix.Project.config()[:app]
    prefix = find_option(rest, "p", "prefix") || "default"

    with(
      {:ok, config} <- fetch_config(otp_app, env, prefix),
      {:ok, updated_data} <-
        open_file_on_edit(editor, SecretVault.get(config, name))
    ) do
      SecretVault.put(config, name, updated_data)
    else
      {:error, {:no_configuration_for_prefix, prefix}} ->
        Mix.shell().error(
          "No configuration for prefix #{inspect(prefix)} found"
        )

      {:error, :no_vaults_configured} ->
        Mix.shell().error("No vaults configured for the app")

      {:error, :no_prefix_provided_when_multiple_configured} ->
        message =
          "No prefix provided when multiple configured. " <>
            "Use --prefix option to specify the prefix"

        Mix.shell().error(message)

      {:error, {:non_zero_exit_code, code, message}} ->
        Mix.shell().error("Non zero exit code #{code}: #{message}")

      {:error, {:executable_not_found, editor}} ->
        Mix.shell().error("Editor not found: #{editor}")

      {:error, :secret_not_found} ->
        message = "Secret #{name} not found in environment #{inspect(env)}"
        Mix.shell().error(message)

      {:error, :unknown_prefix} ->
        Mix.shell().error(
          "Prefix #{inspect(prefix)} for environment #{inspect(env)} does not exist"
        )
    end
  end

  def run(_args) do
    msg = "Invalid number of arguments. Use `mix help scr.edit`."
    Mix.shell().error(msg)
  end

  @spec find_editor() :: String.t()
  def find_editor do
    [
      System.get_env("VISUAL"),
      System.get_env("EDITOR"),
      "xdg-open"
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  @spec open_file_on_edit(editor, data) :: {:ok, data} | {:error, error}
        when editor: String.t(),
             data: String.t(),
             error:
               {:non_zero_exit_code, code :: integer, message :: String.t()}
               | {:executable_not_found, editor :: String.t()}
  def open_file_on_edit(editor, data)
      when is_binary(editor) and is_binary(data) do
    tmp_path = accuire_tmp_file!()
    File.write!(tmp_path, data)

    case do_open_file_on_edit(editor, tmp_path) do
      :ok ->
        data = File.read!(tmp_path)
        File.rm!(tmp_path)
        {:ok, data}

      error ->
        # Trying to delete tmp_path to make sure it's not left behind.
        # It's possible that the file was not even created, so we
        # cannot fail if the file does not exist.
        File.rm(tmp_path)
        error
    end
  end

  defp do_open_file_on_edit(editor, tmp_path) do
    with(
      exe when not is_nil(exe) <- System.find_executable(editor),
      {_, 0} <- System.cmd(editor, [tmp_path])
    ) do
      :ok
    else
      nil -> {:error, {:executable_not_found, editor}}
      {msg, code} -> {:error, {:non_zero_exit_code, code, msg}}
    end
  catch
    :error, error when error in ~w[enoent eacces]a ->
      {:error, {:executable_not_found, editor}}
  end

  defp accuire_tmp_file! do
    tmp_file_name = Base.encode16(:crypto.strong_rand_bytes(16)) <> ".txt"
    tmp_path = Path.join(System.tmp_dir!(), tmp_file_name)
    File.mkdir_p!(Path.dirname(tmp_path))
    File.touch!(tmp_path)
    # Read/write for owner only
    File.chmod!(tmp_path, 0o600)
    tmp_path
  end
end
