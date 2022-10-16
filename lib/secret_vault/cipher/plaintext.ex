defmodule SecretVault.Cipher.Plaintext do
  @moduledoc """
  Stores passwords in plaintext.

  Implements `SecretVault.Cipher`.

  > #### Warning {: .warning }
  >
  > This cipher is insecure and supposed to be used only in testing
  > or self encrypting filesystems.
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
