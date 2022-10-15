defmodule SecretVault.Cipher.ErlangCrypto do
  @moduledoc """
  Encryption provider that uses `:crypto` module.

  Implements `SecretVault.Cipher`.
  """

  import :crypto,
    only: [
      crypto_one_time_aead: 6,
      crypto_one_time_aead: 7,
      strong_rand_bytes: 1
    ]

  alias SecretVault.Cipher

  @behaviour Cipher

  @default_cipher :aes_256_gcm

  @impl true
  def encrypt(key, plain_text, _opts) do
    iv = strong_rand_bytes(12)
    aad = ""

    {encrypted_plain_text, meta} =
      crypto_one_time_aead(
        @default_cipher,
        key,
        iv,
        plain_text,
        aad,
        true
      )

    Cipher.pack("AES256GCM", [iv, aad, meta, encrypted_plain_text])
  end

  @impl true
  def decrypt(key, cipher_text, _opts) do
    case Cipher.unpack(cipher_text) do
      {:ok, "AES256GCM", [iv, aad, meta, encrypted_plain_text]} ->
        crypto_one_time_aead(
          @default_cipher,
          key,
          iv,
          encrypted_plain_text,
          aad,
          meta,
          false
        )

      _ ->
        # TODO
        raise "Bad base16"
    end
  end
end
