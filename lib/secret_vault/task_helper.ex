defmodule SecretVault.TaskHelper do
  @moduledoc false
  # This module is a set of helpers for tasks

  alias SecretVault.Config

  @spec fetch_config(atom(), String.t(), Config.prefix()) :: {:ok, Config.t()} | {:error, error}
        when error: :no_vaults_configured
               | {:no_configuration_for_prefix, Config.prefix()}
  def fetch_config(otp_app, env, nil), do: fetch_config(otp_app, env, "default")
  def fetch_config(otp_app, env, prefix) do
    with {:ok, prefixes} <- Application.fetch_env(otp_app, :secret_vault) do
      opts = Enum.find_value(prefixes, fn {key, opts} -> to_string(key) == prefix && opts end)
      priv_dir = File.cwd!()
      opts =
        opts
        |> Keyword.put(:prefix, prefix)
        |> Keyword.put(:priv_dir, priv_dir)

      config = Config.new(otp_app, opts)
      {:ok, %Config{config | env: env}}
    end
  end

  @spec find_option([String.t()], String.t(), String.t()) :: String.t() | nil
  def find_option(["--" <> option, value | _rest], _short, option), do: value
  def find_option(["-" <> short, value | _rest], short, _option), do: value
  def find_option([_ | rest], short, option), do: find_option(rest, short, option)
  def find_option([], _, _), do: nil
end
