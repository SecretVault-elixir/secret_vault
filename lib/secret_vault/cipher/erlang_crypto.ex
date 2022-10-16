defmodule SecretVault.Cipher.ErlangCrypto do
  @moduledoc """
  Encryption provider that uses `:crypto` module.

  Implements `SecretVault.Cipher`.

  As for now it uses `:aes_256_gcm` mode as default and only option.
  """

  import :crypto,
    only: [
      crypto_one_time_aead: 6,
      crypto_one_time_aead: 7,
      strong_rand_bytes: 1
    ]

  alias SecretVault.Cipher

  @behaviour Cipher

  @default_algorithm :aes_256_gcm
  @cipher_name "ErlangCrypto"
  @default_algorithm_name "AES256GCM"

  @impl true
  def encrypt(key, plain_text, _opts) do
    iv = strong_rand_bytes(12)
    aad = ""

    {encrypted_plain_text, meta} =
      crypto_one_time_aead(
        @default_algorithm,
        key,
        iv,
        plain_text,
        aad,
        true
      )

    Cipher.pack(@cipher_name, @default_algorithm_name, [
      iv,
      aad,
      meta,
      encrypted_plain_text
    ])
  end

  @impl true
  def decrypt(key, cipher_text, _opts) do
    case Cipher.unpack!(@cipher_name, cipher_text) do
      [@default_algorithm_name, iv, aad, meta, encrypted_plain_text] ->
        decrypt_result =
          crypto_one_time_aead(
            @default_algorithm,
            key,
            iv,
            encrypted_plain_text,
            aad,
            meta,
            false
          )

        case decrypt_result do
          :error -> {:error, :invalid_encryption_key}
          data when is_binary(data) -> {:ok, data}
        end

      list ->
        raise Cipher.Error,
              "Wrong amount of properties. Expected five props: algo, iv, aad, meta, encrypted_plain_text. Got #{length(list)}"
    end
  end
end
