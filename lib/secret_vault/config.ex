defmodule SecretVault.Config do
  @moduledoc """
  Keeps configuration for a `SecretVault.Storage`.
  """

  defstruct [:key, :env] ++
              [
                cipher: SecretVault.Cipher.ErlangCrypto,
                cipher_opts: [],
                priv_path: nil,
                prefix: "default"
              ]

  @typedoc """
  A module implementing `SecretVault.EncryptionProvider` behaviour.
  """
  @type cipher :: module

  @typedoc """
  Options for specified provider.
  """
  @type cipher_opts :: Keyword.t()

  @typedoc """
  A module implementing `SecretVault.KeyDerivation`
  """
  @type key_derivation :: module

  @typedoc """
  Options for specified key derivation function.
  """
  @type key_derivation_opts :: Keyword.t()

  @typedoc """
  Priv path. Use it only when you wan't to specify it by hands.
  """
  @type priv_path :: String.t()

  @typedoc """
  Path prefix for your secrets in priv directory.

  It's usefull when you want to have more than one secret storage.
  Defaults to `secrets`.
  """
  @type prefix :: String.t()

  @typedoc """
  Simmetric key for cipher
  """
  @type key :: binary()

  @typedoc """
  Plain string password
  """
  @type password :: String.t()

  @typedoc """
  """
  @type t :: %__MODULE__{
          cipher_opts: cipher_opts(),
          cipher: cipher(),
          key: key(),
          env: String.t(),
          priv_path: priv_path(),
          prefix: prefix()
        }

  # For Mix projects we can have this variable in compile-time
  # For non-Mix projects we can specify this variable in runtime
  # or work without `env` path at all
  env =
    if Code.ensure_loaded?(Mix) && function_exported?(Mix, :env, 0) do
      to_string(Mix.env())
    else
      ""
    end

  @doc """
  Creates a struct that keeps configuration data for the storage.

  `app_name` is an OTP application name for the app you want to
  keep secrets for.
  """
  @spec new(app_name :: atom, [option]) :: t
        when option:
               {:cipher, cipher}
               | {:cipher_opts, cipher_opts}
               | {:key_derivation, key_derivation}
               | {:key_derivation_opts, key_derivation_opts}
               | {:priv_path, priv_path}
               | {:prefix, prefix}
               | {:password, password()}
               | {:key, key()}
               | {:env, String.t()}
  def new(app_name, opts \\ []) when is_atom(app_name) and is_list(opts) do
    key =
      cond do
        key = opts[:key] ->
          key

        password = opts[:password] ->
          key_derivation =
            Keyword.get(opts, :key_derivation, SecretVault.KDFs.PBKDF2)

          key_derivation_opts = Keyword.get(opts, :key_derivation_opts, [])
          key_derivation.kdf(password, key_derivation_opts)

        true ->
          raise "No password or key specified"
      end

    opts =
      opts
      |> Keyword.put_new_lazy(:priv_path, fn ->
        to_string(:code.priv_dir(app_name))
      end)
      |> Keyword.put_new(:prefix, "secrets")
      |> Keyword.put_new(:env, to_string(unquote(env)))
      |> Keyword.put_new(:key, key)

    struct(__MODULE__, [{:key, key} | opts])
  end

  current_environment = "#{Mix.env()}"

  @doc """
  Same as `fetch_from_env/3`, but passes `env` authomatically.
  """
  @spec fetch_from_env(atom(), prefix()) ::
          {:ok, t()}
          | :error
          | {:error, {:no_configuration_for_prefix, prefix()}}
  def fetch_from_env(otp_app, prefix)
      when is_atom(otp_app) and is_binary(prefix) do
    fetch_from_env(otp_app, unquote(current_environment), prefix)
  end

  @doc """
  Fetch config from the application configuration (e.g. in
  `confix.exs`).

  `otp_app` is the current OTP application name. `env` is `Mix.env()`
  value as a binary (string). `prefix` must be one of the configured
  prefixes.
  """
  @spec fetch_from_env(atom(), String.t(), prefix()) ::
          {:ok, t()}
          | :error
          | {:error, {:no_configuration_for_prefix, prefix()}}
  def fetch_from_env(otp_app, env, prefix)
      when is_atom(otp_app) and is_binary(env) and is_binary(prefix) do
    with {:ok, prefixes} <- Application.fetch_env(otp_app, :secret_vault),
         {:ok, opts} <- find_prefix(prefixes, prefix) do
      priv_dir = File.cwd!()

      opts =
        opts
        |> Keyword.put(:prefix, prefix)
        |> Keyword.put(:priv_dir, priv_dir)

      config = new(otp_app, opts)
      {:ok, %__MODULE__{config | env: env}}
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

  # This function is required primarily for doctests
  if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0) and
       Mix.env() == :test do
    def test_config do
      new(:secret_vault,
        password: "123456",
        prefix: "#{:erlang.unique_integer([:positive])}"
      )
    end
  end
end
