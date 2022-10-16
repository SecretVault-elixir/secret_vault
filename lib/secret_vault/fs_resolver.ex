defmodule SecretVault.FSResolver do
  @moduledoc false
  # This is a helper module that incapsulates file paths resolution
  # for the storage.

  alias SecretVault.Config

  @spec resolve_file_path(Config.t(), String.t(), String.t()) :: String.t()
  def resolve_file_path(config, environment, name)
      when is_map(config) and is_binary(environment) and is_binary(name) do
    file_name = "#{name}.vault_secret"
    Path.join([resolve_environment_path(config, environment), file_name])
  end

  @spec resolve_environment_path(Config.t(), String.t()) :: String.t()
  def resolve_environment_path(config, environment)
      when is_map(config) and is_binary(environment) do
    Path.join([config.priv_path, config.prefix, environment])
  end
end
