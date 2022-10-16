defmodule SecretVault.Cipher.Plaintext do
  @moduledoc """
  Stores passwords in plaintext. Do not use this anywhere except the development.
  And please, if you're using this, make sure that the passwords are unique.
  """

  alias SecretVault.Cipher

  @behaviour Cipher

  @impl true
  def encrypt(_key, plain_text, _opts) do
    Cipher.pack("PLAIN", [plain_text])
  end

  @impl true
  def decrypt(_key, cipher_text, _opts) do
    case Cipher.unpack(cipher_text) do
      {:ok, "PLAIN", plaintext} ->
        Enum.join(plaintext, ";")

      _ ->
        # TODO
        raise "Bad base16"
    end
  end
end
