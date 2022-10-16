defmodule SecretVault do
  @moduledoc """
  Runtime interface to manipulate on-disk secrets.
  """

  alias SecretVault.Config

  defmodule Error do
    @moduledoc """
    Exception for bang functions in `SecretVault`.
    """
    defexception [:message, :reason]
  end

  @typedoc """
  - `:unknown_prefix` means that directory with secrets is not present on disk
  - `:secret_not_found` means that secret file itself is not present
  """
  @type reason ::
          {:unknown_prefix, Config.prefix(), env :: String.t()}
          | {:secret_not_found, name :: String.t(), env :: String.t()}

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
  Show all secrets' names available. It reads secrets from directory specified by `config`
  and retruns a list of names with no particular order.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.put(config, "admin_password", "another_password")
      iex> {:ok, names} = SecretVault.list(config)
      iex> "db_password" in names
      true
      iex> "admin_password" in names
      true
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
        {:error, {:unknown_prefix, config.prefix, config.env}}
    end
  end

  @doc """
  Put `data` as a value of the secret `name` using the `config`. This function
  writes encrypted data to the disk, therefore use this with caution. If you
  want to write data in runtime, it is recommended to create singleton
  process to perform mutating operations

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.get(config, "db_password")
      "super_secret_password"
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
  Get a clear text value of the secret `name` using the `config`. Reads
  a data from disk storage, decrypts it, and returns the default if secret was not found.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.get(config, "db_password")
      "super_secret_password"
      iex> SecretVault.get(config, "non_present_password")
      ""
  """
  @spec get(Config.t(), name(), default :: value()) :: value()
  def get(%Config{} = config, name, default \\ "") do
    case fetch(config, name) do
      {:ok, data} ->
        data

      {:error, _reason} ->
        default
    end
  end

  @doc """
  Fetch a clear text value of the secret `name` using the `config`. Reads
  a data from disk storage, decrypts it, and returns the result of an operation
  in an "either" manner.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.fetch(config, "db_password")
      {:ok, "super_secret_password"}
      iex> SecretVault.fetch(config, "non_present_password")
      {:error, {:secret_not_found, "non_present_password", "test"}}
  """
  @spec fetch(Config.t(), name) :: {:ok, value} | {:error, error}
        when error: reason | :invalid_encryption_key
  def fetch(%Config{} = config, name) when is_binary(name) do
    at_path(config, name, fn file_path ->
      encrypted_data = File.read!(file_path)

      config.cipher.decrypt(
        config.key,
        encrypted_data,
        config.cipher_opts
      )
    end)
  end

  @doc """
  Fetch a clear text value of the secret `name` using the `config`.

  Fetch a clear text value of the secret `name` using the `config`. Reads
  a data from disk storage, decrypts it, and returns the decrypted data or
  raises if no secret with the `name` found.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.fetch!(config, "db_password")
      "super_secret_password"
  """
  @spec fetch!(Config.t(), name()) :: value()
  def fetch!(%Config{} = config, name) do
    case fetch(config, name) do
      {:ok, data} ->
        data

      # TODO
      {:error, reason} ->
        raise Error, message: "Couldn't fetch the secret", reason: reason
    end
  end

  @doc """
  Asynchronously fetches all secrets from the vault specified by the `config` from disk.
  This function returns a map or error in "either" manner.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.put(config, "admin_password", "another_password")
      iex> SecretVault.fetch_all(config)
      {:ok, %{"db_password" => "super_secret_password", "admin_password" => "another_password"}}
  """
  @spec fetch_all(Config.t()) ::
          {:ok, %{name() => value()}}
          | {:error, {name(), reason()}}
          | {:error, reason()}
  def fetch_all(%Config{} = config) do
    at_all_names(config, {:ok, %{}}, fn name, value, {:ok, acc} ->
      {:cont, {:ok, Map.put(acc, name, value)}}
    end)
  end

  @doc """
  Remove secret `name` from the vault specified by the `config` from disk.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.delete(config, "db_password")
      iex> SecretVault.fetch(config, "db_password")
      {:error, {:secret_not_found, "db_password", "test"}}
  """
  @spec delete(Config.t(), name()) :: :ok | {:error, reason()}
  def delete(%Config{} = config, name) when is_binary(name) do
    at_path(config, name, &File.rm/1)
  end

  @doc """
  Tells whether the secret `name` exists.

  Example:
      iex> config = SecretVault.Config.test_config
      iex> SecretVault.put(config, "db_password", "super_secret_password")
      iex> SecretVault.exists?(config, "db_password")
      true
      iex> SecretVault.exists?(config, "non_present_password")
      false
  """
  @spec exists?(Config.t(), name()) :: boolean()
  def exists?(config, name) do
    case at_path(config, name, &{:ok, &1}) do
      {:ok, _} -> true
      {:error, _} -> false
    end
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

  @spec at_path(Config.t(), name(), (Path.t() -> any())) :: any()
  defp at_path(config, name, closure) do
    path = resolve_environment_path(config)
    file_path = resolve_secret_path(config, name)

    cond do
      File.exists?(file_path) ->
        closure.(file_path)

      not File.exists?(path) ->
        {:error, {:unknown_prefix, config.prefix, config.env}}

      true ->
        {:error, {:secret_not_found, name, config.env}}
    end
  end

  @spec at_all_names(
          Config.t(),
          acc,
          (name(), value(), acc -> {:cont, acc} | {:halt, res})
        ) :: acc | res | {:error, {name, reason}}
        when acc: any(), res: any()
  defp at_all_names(config, acc, closure) do
    with {:ok, list} <- list(config) do
      list
      |> Task.async_stream(
        fn name -> {name, fetch(config, name)} end,
        # Because file operations are concurrent
        max_concurrency: System.schedulers_online() * 8,
        ordered: false
      )
      |> Enum.reduce_while(acc, fn
        {:ok, {name, {:ok, value}}}, acc ->
          closure.(name, value, acc)

        {:ok, {name, {:error, reason}}}, _acc ->
          {:halt, {:error, {name, reason}}}
      end)
    end
  end
end
