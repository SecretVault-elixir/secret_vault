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
  @default_cipher_name "ErlangCrypto"

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

    Cipher.pack(@default_cipher_name, [iv, aad, meta, encrypted_plain_text])
  end

  @impl true
  def decrypt(key, cipher_text, _opts) do
    case Cipher.unpack!(@default_cipher_name, cipher_text) do
      [iv, aad, meta, encrypted_plain_text] ->
        crypto_one_time_aead(
          @default_cipher,
          key,
          iv,
          encrypted_plain_text,
          aad,
          meta,
          false
        )

      list ->
        raise Cipher.Error,
              "Wrong amount of properties. Expected five props: iv, aad, meta, encrypted_plain_text. Got #{length(list)}"
    end
  end
end
