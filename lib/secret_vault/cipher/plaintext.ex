defmodule SecretVault.Cipher.Plaintext do
  @moduledoc """
  Stores passwords in plaintext. Do not use this anywhere except the development.
  And please, if you're using this, make sure that the passwords are unique.
  """

  alias SecretVault.Cipher

  @behaviour Cipher

  @impl true
  def encrypt(_key, plain_text, _opts) do
    Cipher.pack("PLAIN", "PLAIN", [plain_text])
  end

  @impl true
  def decrypt(_key, cipher_text, _opts) do
    ["PLAIN", splitted_plaintext] = Cipher.unpack!("PLAIN", cipher_text)
    {:ok, Enum.join(splitted_plaintext, ";")}
  end
end
