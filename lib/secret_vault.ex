defmodule SecretVault do
  @moduledoc """
  Provides a way to access existing stored secrets.
  """

  alias SecretVault.Config

  @typedoc """
  - `:unknown_prefix` means that directory with secrets is not present on disk
  - `:secret_not_found` means that secret file itself is not present
  """
  @type reason :: :unknown_prefix | :secret_not_found

  @typedoc """
  Name of a secret
  """
  @type name :: String.t()

  @typedoc """
  Binary value you want to store in secret.
  To store arbitary structures, try usings `:erlang.term_to_binary/2`
  """
  @type value :: binary()

  extension = ".vault_secret"

  @doc """
  Show secrets available in the `environment`.
  """
  @spec list(Config.t()) :: {:ok, [String.t()]} | {:error, :unknown_prefix}
  def list(%Config{} = config) do
    case File.ls(resolve_environment_path(config)) do
      {:ok, files} ->
        files =
          Enum.map(files, fn filename ->
            {name, unquote(extension)} =
              String.split_at(filename, -unquote(byte_size(extension)))

            name
          end)

        {:ok, files}

      {:error, _} ->
        {:error, :unknown_prefix}
    end
  end

  @doc """
  Put `data` as a value of the secret `name` in the `environment`
  encrypted with the `key` and using the `config`.
  """
  @spec put(Config.t(), name(), value()) :: :ok | {:error, File.posix()}
  def put(%Config{} = config, name, data)
      when is_binary(name) and is_binary(data) do
    encrypted_data =
      config.cipher.encrypt(
        config.key,
        data,
        config.cipher_opts
      )

    path = resolve_environment_path(config)
    file_path = resolve_secret_path(config, name)

    with :ok <- File.mkdir_p(path) do
      File.write(file_path, encrypted_data)
    end
  end

  @doc """
  Fetch a clear text value of the secret `name` in the `environment`
  encrypted with the `key` and using the `config`.
  """
  @spec fetch(Config.t(), name()) :: {:ok, value()} | {:error, reason()}
  def fetch(%Config{} = config, name) when is_binary(name) do
    at_path(config, name, fn file_path ->
      encrypted_data = File.read!(file_path)

      data =
        config.cipher.decrypt(
          config.key,
          encrypted_data,
          config.cipher_opts
        )

      {:ok, data}
    end)
  end

  @doc """
  Remove secret `name` from the `environment`.
  """
  @spec delete(Config.t(), name()) :: :ok | {:error, reason()}
  def delete(%Config{} = config, name) when is_binary(name) do
    at_path(config, name, &File.rm/1)
  end

  # Resolves a path to the `name` secret
  @doc false
  @spec resolve_secret_path(Config.t(), name()) :: Path.t()
  def resolve_secret_path(%Config{} = config, name) when is_binary(name) do
    file_name = name <> unquote(extension)
    Path.join([resolve_environment_path(config), file_name])
  end

  # Resolves a path to the prefixed directory with secrets
  @doc false
  @spec resolve_environment_path(Config.t()) :: Path.t()
  def resolve_environment_path(config) do
    %Config{priv_path: priv_path, env: env, prefix: prefix} = config
    Path.join([priv_path, "secret_vault", env, prefix])
  end

  # Helpers

  defp at_path(config, name, closure) do
    path = resolve_environment_path(config)
    file_path = resolve_secret_path(config, name)

    cond do
      File.exists?(file_path) -> closure.(file_path)
      not File.exists?(path) -> {:error, :unknown_prefix}
      true -> {:error, :secret_not_found}
    end
  end
end
