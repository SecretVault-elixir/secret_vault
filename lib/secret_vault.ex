defmodule SecretVault do
  @moduledoc """
  Provides a way to access existing stored secrets.
  """

  alias SecretVault.{Config, FSResolver}

  @doc """
  Show secrets available in the `environment`.
  """
  @spec list_secrets(Config.t(), String.t()) ::
          {:ok, [String.t()]} | {:error, :unknown_environment}
  def list_secrets(config, environment) when is_binary(environment) do
    environment_path = FSResolver.resolve_environment_path(config, environment)

    with {:error, _} <- File.ls(environment_path) do
      {:error, :unknown_environment}
    end
  end

  @doc """
  Put `data` as a value of the secret `name` in the `environment`
  encrypted with the `key` and using the `config`.
  """
  @spec put_secret(Config.t(), String.t(), String.t(), String.t(), String.t()) ::
          :ok
  def put_secret(config, key, environment, name, data)
      when is_binary(key) and is_binary(environment) and is_binary(name) and
             is_binary(data) do
    key = config.key_derivation.kdf(key, config.key_derivation_opts)

    encrypted_data =
      config.encryption_provider.encrypt(
        key,
        data,
        config.encryption_provider_opts
      )

    environment_path = FSResolver.resolve_environment_path(config, environment)
    file_path = FSResolver.resolve_file_path(config, environment, name)

    File.mkdir_p!(environment_path)
    File.write!(file_path, encrypted_data)
  end

  @doc """
  Fetch a clear text value of the secret `name` in the `environment`
  encrypted with the `key` and using the `config`.
  """
  @spec fetch_secret(Config.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, error}
        when error: :secret_not_found | :unknown_environment
  def fetch_secret(config, key, environment, name)
      when is_binary(key) and is_binary(environment) and is_binary(name) do
    key = config.key_derivation.kdf(key, config.key_derivation_opts)

    environment_path = FSResolver.resolve_environment_path(config, environment)
    file_path = FSResolver.resolve_file_path(config, environment, name)

    cond do
      not File.exists?(environment_path) ->
        {:error, :unknown_environment}

      not File.exists?(file_path) ->
        {:error, :secret_not_found}

      true ->
        encrypted_data = File.read!(file_path)

        data =
          config.encryption_provider.decrypt(
            key,
            encrypted_data,
            config.encryption_provider_opts
          )

        {:ok, data}
    end
  end

  @doc """
  Remove secret `name` from the `environment`.
  """
  @spec delete_secret(Config.t(), String.t(), String.t()) ::
          :ok | {:error, error}
        when error: :secret_not_found | :unknown_environment
  def delete_secret(config, environment, name)
      when is_binary(environment) and is_binary(name) do
    environment_path = FSResolver.resolve_environment_path(config, environment)
    file_path = FSResolver.resolve_file_path(config, environment, name)

    cond do
      not File.exists?(environment_path) -> {:error, :unknown_environment}
      not File.exists?(file_path) -> {:error, :secret_not_found}
      true -> File.rm!(file_path)
    end
  end
end
