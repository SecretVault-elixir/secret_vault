defmodule SecretVault.EncryptionProvider do
  @moduledoc """
  Provides an interface to implement encryption methods.
  """

  @typedoc """
  A key for symetric encryption algorithm as a binary.
  """
  @type key :: binary()

  @typedoc """
  Binary blob that contains encrypted data.
  """
  @type cypher_text :: binary()

  @typedoc """
  Binary blob that contains decrypted data.
  """
  @type plain_text :: binary()

  @doc """
  Encrypt the `plain_text` with the `key`.
  """
  @callback encrypt(key, plain_text, opts) :: cypher_text
            when opts: Keyword.t()

  @doc """
  Decrypt the `cypher_text` with the `key` used to get it.
  """
  @callback decrypt(key, cypher_text, opts) :: plain_text
            when opts: Keyword.t()
end
