defmodule SecretVault.EditorHelper do
  @moduledoc false
  # This module incapsulates working with starting a text editor.

  @spec open_new_file(editor) :: {:ok, data} | {:error, error}
        when editor: String.t(),
             data: String.t(),
             error:
               {:non_zero_exit_code, code :: integer, message :: String.t()}
               | {:executable_not_found, editor :: String.t()}
  def open_new_file(editor) do
    open_file_on_edit(editor, "")
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

      {:error, _} = error ->
        # Trying to delete tmp_path to make sure it's not left behind.
        # It's possible that the file was not even created, so we
        # cannot fail if the file does not exist.
        File.rm(tmp_path)
        error
    end
  end

  defp do_open_file_on_edit(editor, tmp_path) do
    case System.cmd(editor, [tmp_path]) do
      {_, 0} -> :ok
      {msg, code} -> {:error, {:non_zero_exit_code, code, msg}}
    end
  catch
    :error, error when error in ~w[enoent eacces]a ->
      {:error, {:executable_not_found, editor}}
  end

  defp accuire_tmp_file! do
    tmp_file_name = Base.encode16(:crypto.strong_rand_bytes(16))
    tmp_path = Path.join(System.tmp_dir!(), tmp_file_name)
    tmp_base_path = Path.dirname(tmp_path)
    File.mkdir_p!(tmp_base_path)
    tmp_path
  end
end
