defmodule SecretVault.EncryptionProviders.ErlangCryptoTest do
  use ExUnit.Case

  alias SecretVault.EncryptionProviders.ErlangCrypto

  test "encryption and decription return original result" do
    key = :crypto.strong_rand_bytes(32)
    text = "test"

    c = ErlangCrypto.encrypt(key, text, [])
    p = ErlangCrypto.decrypt(key, c, [])

    assert p == text
  end
end
