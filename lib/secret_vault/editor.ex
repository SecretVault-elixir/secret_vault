defmodule SecretVault.Editor do
  @moduledoc false
  # This module incapsulates working with starting a text editor.

  @spec open_new_file() :: {:ok, data} | {:error, error}
        when data: String.t(),
             error:
               {:non_zero_exit_code, code :: integer, message :: String.t()}
               | {:executable_not_found, editor :: String.t()}
  def open_new_file do
    open_file_on_edit("")
  end

  @spec open_file_on_edit(data) :: {:ok, data} | {:error, error}
        when data: String.t(),
             error:
               {:non_zero_exit_code, code :: integer, message :: String.t()}
               | {:executable_not_found, editor :: String.t()}
  def open_file_on_edit(data) when is_binary(data) do
    editor = find_editor()
    tmp_path = accuire_tmp_file!()
    File.write!(tmp_path, data)

    case do_open_file_on_edit(editor, tmp_path) do
      :ok ->
        data = File.read!(tmp_path)
        File.rm!(tmp_path)
        {:ok, data}

      {:error, _} = error ->
        # Trying to delete tmp_path to make sure it's not left behind.
        # It's possible that the file was not even created, so we
        # cannot fail if the file does not exist.
        File.rm(tmp_path)
        error
    end
  end

  defp do_open_file_on_edit(editor, tmp_path) do
    with exe when not is_nil(exe) <- System.find_executable(editor),
         running_editor <- run_editor(exe, tmp_path) do
      await_editor(running_editor)
    else
      nil -> {:error, {:executable_not_found, editor}}
      {msg, code} -> {:error, {:non_zero_exit_code, code, msg}}
    end
  catch
    :error, error when error in ~w[enoent eacces]a ->
      {:error, {:executable_not_found, editor}}
  end

  # Starts editor instance in a separate port
  defp run_editor(editor_path, tmp_path) do
    Port.open({:spawn_executable, editor_path}, [
      :nouse_stdio,
      :exit_status,
      :eof,
      args: [tmp_path]
    ])
  end

  # Awaits exit code from the editor for 10 minutes
  defp await_editor(port, timeout \\ 10 * 60_000) do
    receive do
      {^port, {:exit_status, 0}} -> :ok
      {^port, {:exit_status, status}} -> {:error, {:non_zero_exit_code, status}}
    after
      timeout ->
        Port.close(port)
        {:error, :timeout}
    end
  end

  # Searches for the editor command in EDITOR, VISUAL and xdg-open command
  defp find_editor do
    editor_candidates = [
      System.get_env("VISUAL"),
      System.get_env("EDITOR"),
      "xdg-open"
    ]

    Enum.find(editor_candidates, &(&1 not in [nil, ""]))
  end

  # Creates a protected file in tmp upon which the editor will be called
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
