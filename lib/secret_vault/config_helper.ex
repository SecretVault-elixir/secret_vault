defmodule SecretVault.ConfigHelper do
  @moduledoc false
  # Incapsulates working with OTP configs.

  alias SecretVault.Config

  @spec fetch_config(otp_app, prefix) :: {:ok, Config.t()} | {:error, error}
        when otp_app: atom,
             prefix: atom,
             error:
               :no_vaults_configured
               | {:no_configuration_for_prefix, prefix}
  def fetch_config(otp_app, prefix \\ nil) do
    with {:ok, prefixes} <- list_available_configs(otp_app),
         {:ok, prefix} <- fetch_requested_prefix(prefixes, prefix) do
      get_config(otp_app, prefix)
    end
  end

  defp list_available_configs(otp_app) do
    config = Application.get_env(otp_app, :secret_vault)

    case config[:prefixes] do
      nil -> {:error, :no_vaults_configured}
      prefixes when is_list(prefixes) -> {:ok, prefixes}
    end
  end

  defp fetch_requested_prefix([prefix], nil) do
    {:ok, prefix}
  end

  defp fetch_requested_prefix([prefix], prefix) do
    {:ok, prefix}
  end

  defp fetch_requested_prefix(_prefixes, nil) do
    {:error, :no_prefix_provided_when_multiple_configured}
  end

  defp fetch_requested_prefix(prefixes, prefix) do
    if Enum.member?(prefixes, prefix) do
      {:ok, prefix}
    else
      {:error, {:no_configuration_for_prefix, prefix}}
    end
  end

  defp get_config(otp_app, prefix) do
    config = Application.get_env(otp_app, :secret_vault)

    case config[prefix] do
      nil ->
        {:error, {:no_configuration_for_prefix, prefix}}

      opts ->
        config_opts = Keyword.put(opts, :prefix, "#{prefix}")
        {:ok, Config.new(otp_app, config_opts)}
    end
  end
end
