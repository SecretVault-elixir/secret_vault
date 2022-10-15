defmodule SecretVault.Config do
  @moduledoc """
  Keeps configuration for a `SecretVault.Storage`.
  """

  defstruct encryption_provider: SecretVault.Cipher.ErlangCrypto,
            encryption_provider_opts: [],
            key_derivation: SecretVault.KDFs.PBKDF2,
            key_derivation_opts: [],
            priv_path: nil,
            prefix: nil

  @type t :: %__MODULE__{
          encryption_provider: module,
          key_derivation: module,
          priv_path: String.t(),
          prefix: String.t()
        }

  @typedoc """
  A module implementing `SecretVault.EncryptionProvider` behaviour.
  """
  @type encryption_provider :: module

  @typedoc """
  Options for specified provider.
  """
  @type encryption_provider_opts :: Keyword.t()

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

  @doc """
  Creates a struct that keeps configuration data for the storage.

  `app_name` is an OTP application name for the app you want to
  keep secrets for.
  """
  @spec new(atom, [option]) :: t
        when option:
               {:encryption_provider, encryption_provider}
               | {:encryption_provider_opts, encryption_provider_opts}
               | {:key_derivation, key_derivation}
               | {:key_derivation_opts, key_derivation_opts}
               | {:priv_path, priv_path}
               | {:prefix, prefix}
  def new(app_name, opts \\ []) when is_atom(app_name) and is_list(opts) do
    opts =
      opts
      |> Keyword.put_new_lazy(:priv_path, fn ->
        app_name |> :code.priv_dir() |> to_string
      end)
      |> Keyword.put_new(:prefix, "secrets")

    struct(__MODULE__, opts)
  end
end
