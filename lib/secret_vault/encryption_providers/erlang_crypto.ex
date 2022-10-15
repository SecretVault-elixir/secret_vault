defmodule SecretVault.EncryptionProviders.ErlangCrypto do
  @moduledoc """
  Encryption provider that uses `:crypto` module.

  Implements `SecretVault.EncryptionProvider`.
  """

  import :crypto,
    only: [
      crypto_one_time_aead: 6,
      crypto_one_time_aead: 7,
      strong_rand_bytes: 1
    ]

  @behaviour SecretVault.EncryptionProvider

  @default_cypher :aes_256_gcm

  @impl true
  def encrypt(key, plain_text, _opts) do
    iv = strong_rand_bytes(12)
    aad = ""

    {encrypted_plain_text, meta} =
      crypto_one_time_aead(
        @default_cypher,
        key,
        iv,
        plain_text,
        aad,
        true
      )

    "AES256GCM;#{Base.encode16(iv)};#{Base.encode16(aad)};" <>
      "#{Base.encode16(meta)};#{Base.encode16(encrypted_plain_text)}"
  end

  @impl true
  def decrypt(key, cypher_text, _opts) do
    [
      "AES256GCM",
      iv_base,
      aad_base,
      meta_base,
      encrypted_plain_text_base
    ] = String.split(cypher_text, ";")

    iv = Base.decode16!(iv_base)
    aad = Base.decode16!(aad_base)
    meta = Base.decode16!(meta_base)
    encrypted_plain_text = Base.decode16!(encrypted_plain_text_base)

    crypto_one_time_aead(
      @default_cypher,
      key,
      iv,
      encrypted_plain_text,
      aad,
      meta,
      false
    )
  end
end
