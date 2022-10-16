defmodule SecretVault.TaskHelper do
  @moduledoc false
  # This module is a set of helpers for tasks

  alias SecretVault.Config

  @spec fetch_config(atom(), String.t(), Config.prefix()) ::
          {:ok, Config.t()}
          | :error
          | {:error, {:no_configuration_for_prefix, Config.prefix()}}
  def fetch_config(otp_app, env, prefix) do
    with {:ok, prefixes} <- Application.fetch_env(otp_app, :secret_vault),
         {:ok, opts} <- find_prefix(prefixes, prefix) do
      priv_dir = File.cwd!()

      opts =
        opts
        |> Keyword.put(:prefix, prefix)
        |> Keyword.put(:priv_dir, priv_dir)

      config = Config.new(otp_app, opts)
      {:ok, %Config{config | env: env}}
    end
  end

  defp find_prefix([], prefix) do
    {:error, {:no_configuration_for_prefix, prefix}}
  end

  defp find_prefix([{atom_prefix, opts} | rest], prefix) do
    case to_string(atom_prefix) do
      ^prefix -> {:ok, opts}
      _ -> find_prefix(rest, prefix)
    end
  end

  @spec find_option([String.t()], String.t(), String.t()) :: String.t() | nil
  def find_option(args, short, option)

  def find_option(["--" <> option, value | _rest], _short, option) do
    value
  end

  def find_option(["-" <> short, value | _rest], short, _option) do
    value
  end

  def find_option(["--" <> flag | rest], short, option) do
    case String.split(flag, "=") do
      [^option, value] ->
        value

      _ ->
        find_option(rest, short, option)
    end
  end

  def find_option([_ | rest], short, option) do
    find_option(rest, short, option)
  end

  def find_option([], _, _) do
    nil
  end
end
